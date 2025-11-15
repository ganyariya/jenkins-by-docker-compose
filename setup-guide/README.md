# setup-guide

## Jenkins Controller の設定

http://localhost:8080 を開くと下記のように初期パスワード設定画面が表示されます。

![](./images/01_unlock_jenkins.png)

下記のコマンドで初期 Admin パスワードが確認できます。
表示されたものを入力してください。

```sh
cat jenkins-controller-data/secrets/initialAdminPassword
```

その後は下記のように操作してください。

- Install suggested plugins
- Create First Admin User
  - お好きな Admin User と Password を入力してください
  - ![](./images/02_first_admin_user.png)
- Instance Configuration
  - `Jenkins URL` を `http://localhost:8080/` のまま `Save And Finish` してください
- Complete
  - このような画面になれば完了です
  - ![](./images/03_initial_jenkins.png)

## SSH Agent の設定

それでは SSH Agent Node を作成しパイプライン実行のノードとして利用する、という設定をしましょう。

`Manage Jenkins > Nodes > +New Node` を選択します。
そして SSH Agent Node のための Node 名を設定し Permanent Node として作成しましょう。
ここでは例として `jenkins-ssh-agent1-node` という名前にしています。

![](./images/04_new_ssh_agent1_node.png)

先に **Credential 以外** を設定します。

- `Number of executers`
  - 該当のノードで並列に実行できるビルド数です
  - `2` など、 1 より大きい数字にして構いません
- `Remote root directory`
  - 必ず `/home/jenkins/agent` を指定します
- Labels
  - ここに記載したラベルを Pipeline の `agent` 句における指定で利用します
  - 今回の例では `jenkins-ssh-agent1-label` としています
- Launch method
  - `Launch agents via SSH `
  - Host
    - `jenkins-ssh-agent1` を指定しています
    - compose.yml のサービス名と同じものにしてください
  - `Host Key Verification Strategy`
    - `Non Verifying Verification Strategy`

```yaml
  jenkins-ssh-agent1: # Launch method > Host に設定する
    <<: *jenkins-ssh-agent-definition
```

![](./images/05_ssh_agent1_property_without_credential.png)

ここまで指定したら `Credentials > Add` ボタンを押して、SSH 接続のための認証情報を登録していきます。

![](./images/06_credentials_add.png) 

- Kind
  - `SSH Username with private key`
- ID
  - `jenkins-ssh-agent1-ssh-key`
  - 好きな ID を入力してください
- Username
  - 必ず `jenkins` を入力してください
- Private Key
  - `generate_ssh_key.sh` によって生成された `jenkins_ssh_agent_key` の中身をコピーしてペーストしてください
- Passphrase
  - 空のままでよいです

上記を記載したらこの認証情報を作成してください。

![](./images/07_credentials_setting.png)

その後、そのまま今回作成した認証情報を下記のように設定し、Save してください。

![](./images/08_specify_credentials.png)

作成された jenkins-ssh-agent1-node を開き下記のようになっていれば SSH 接続が成功しています。

![](./images/09_jenkins_ssh_agent1_node.png)
![](./images/10_jenkins_ssh_agent1_node_log.png)

動作確認のために、簡単なサンプルパイプラインを実行してみます。
`TestJob` という `Pipeline` を新たに作成します。

![](./images/11_new_pipeline.png)

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout Source') {
            steps {
                git branch: 'main', url: 'https://github.com/ganyariya/ganyariya.git'
                sh 'ls -a'
            }
        }

        stage('docker build and test') {
            agent {
                docker {
                    image 'node:lts-alpine'
                }
            }
            steps {
                sh 'echo "--- Inside Docker Container ---"'
                sh 'ls -a'
                sh 'node -v'
            }
        }
    }
}
```

![](./images/12_testjob_script.png)

上記で作成した `TestJob` を何回か実行し、 `jenkins-ssh-agent1-node` と `Built-in Node (master)` それぞれで正しく Job が実行できていれば問題ありません。

jenkins-ssh-agent2 サービスに対しても同様の手順で `jenkins-ssh-agent2-node` を作成できます。

```yaml
  jenkins-ssh-agent2:
    <<: *jenkins-ssh-agent-definition
```

### SSH Agent がどういう仕組みで動いているのかの説明

補足として、どのように SSH Agent が Pipeline の Agent として動いているかについて説明します。

`generate_ssh_agent_key` によって

- private key: `jenkins_ssh_agent_key`
- public key: `jenkins_ssh_agent_key.pub`

が生成されます。

また `.env` ファイルが作成され、`JENKINS_AGENT_SSH_PUBKEY=ssh-ed25519 AAAAC3...` のように公開鍵の環境変数が設定されます。

`docker compose up -d` 時に `jenkins/ssh-agent` イメージのコンテナに公開鍵が渡され、自動で `/home/jenkins/.ssh/authorized_keys` に書き込まれます。

```yaml
  environment:
    # jenkins/ssh-agent container automatically registers JENKINS_AGENT_SSH_PUBKEY to `/home/jenkins/.ssh/authorized_keys` on startup
    JENKINS_AGENT_SSH_PUBKEY: ${JENKINS_AGENT_SSH_PUBKEY}
```

あとは Jenkins Web Console 上で設定した `jenkins-ssh-agent1-node` ノードが Private Key を利用して、 ホスト `jenkins-ssh-agent1` へ SSH 接続をリクエストします。
`jenkins-ssh-agent1` には `JENKINS_AGENT_SSH_PUBKEY: ${JENKINS_AGENT_SSH_PUBKEY}` で公開鍵が登録されているため、 SSH 接続リクエストを受け付けて、以降の SSH 接続が正しくおこなえます。

## Inbound TCP/WebSocket Agent の設定

Inbound Agent の場合、あらかじめ Jenkins Web Console 側での作業が必要となります。
`jenkins-inbound-agent1-node` というノードを作成していきます。

![](./images/13_inbound_agent1_node.png)

下記画像のように設定しましょう。
SSH Agent の違いとして `Launch method` が `Launch agent by connecting it to the controller` を選択します。

![](./images/14_inbound_agent1_node_setting.png)

`jenkins-inbound-agent1-node` を開くと下記フォーマットの接続コマンドが利用されます。
このコマンドを Agent にしたいマシンのシェルで実行すると、「`あなたの Jenkins Agent として働きたいです。Agent として登録してください。識別のための secret と name はこれですよ`」と Jenkins Controller へリクエストを送ります。
Jenkins Controller はその secret と name が正しければ Agent として登録します。

ただし、今回は `jenkins/inbound-agent` イメージを利用するため下記のコマンドは実行しません。
docker compose service の環境変数としてこれらの情報を登録し、 inbound-agent コンテナに自動で接続されます。

```bash
curl -sO http://localhost:8080/jnlpJars/agent.jar
java -jar agent.jar -url http://localhost:8080/ -secret JENKINS_SECRET -name JENKINS_AGENT_NAME -webSocket -workDir "/home/jenkins/agent"
```

![](./images/15_inbound_node_index.png)

`.env` を下記のようにしてください。

```env
JENKINS_AGENT_SSH_PUBKEY=ssh-ed25519 AAAA...
JENKINS_INBOUND_AGENT1_SECRET=0b6c317...
JENKINS_INBOUND_AGENT1_NAME=jenkins-inbound-agent1-node
```

これら .env を設定することで compose.yml の環境変数を通じて inboud-agent コンテナへ引き渡されます。

```yaml
      # curl -sO http://localhost:8080/jnlpJars/agent.jar java -jar agent.jar -url http://localhost:8080/ -secret JENKINS_INBOUND_AGENT1_SECRET -name JENKINS_INBOUND_AGENT1_NAME -webSocket -workDir "/home/jenkins/agent"
      # You need to specify the same `-secret` and `-name` arguments as the like above command, shown under `Run from agent command line: (Unix)` on the Jenkins Web Console node status page
      JENKINS_SECRET: ${JENKINS_INBOUND_AGENT1_SECRET}
      JENKINS_AGENT_NAME: ${JENKINS_INBOUND_AGENT1_NAME}
```

環境変数を反映するために下記コマンドを実行して、再度各種コンテナを作成します。

```bash
docker compose down -v && docker compose up -d
```

再起動後 `jenkins-inbound-agent1-node` が `Agent is connected` になっていれば問題ありません。
`TestJob` を再度実行し、正しく Job が実行できるか確認してください。

![](./images/16_inbound_agent1_connected.png)
