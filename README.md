
# jenkins-by-docker-compose

docker compose を利用して jenkins 環境を構築するサンプルです。   
下記に示す Jenkins 環境が作成できます。

- Jenkins Controller
  - 好きなプラグインを `jenkins_plugins.txt` からインストールできます
  - デフォルトの `jenkins_plugins.txt` では以下のプラグインをインストールします
    - BlueOcean
    - Job DSL
    - Docker Pipeline
- Jenkins SSH Agent
- Jenkins Inbound TCP/WebSocket Agent

## Initial Setup

```bash
git clone https://github.com/ganyariya/jenkins-by-docker-compose
cd jenkins-by-docker-compose
```

もし最初からインストールしたい jenkins plugins があるのであれば `jenkins-controller/jenkins_plugins.txt` にプラグイン名を追加してください。

```bash
cat blueocean
# https://plugins.jenkins.io/job-dsl/
job-dsl
# https://docs.cloudbees.com/docs/cloudbees-ci/latest/pipelines/docker-workflow
docker-workflow

# please write your favorite jenkins plugins below, when docker compose build
```

SSH agent ノードと接続するための ssh key を生成し、 image をビルドしたうえで各種サービスを起動します。

```bash
# generate ssh key & create .env file
sh generate_ssh_key.sh

# build images & activate jenkins
docker compose up -d
```

`docker compose up -d` が終わったら `http://localhost:8080` を開いてください。   
Jenkins が起動しているはずです。

ここから Jenkins Web Console を利用した各種設定を行っていきます。    
[Setup Guide](./setup-guide/README.md) を参照してください。

## 動作確認環境

| environment            | status |
| ---------------------- | ------ |
| Docker Desktop for Mac | ✅️      |

