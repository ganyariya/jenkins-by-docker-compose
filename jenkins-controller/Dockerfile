# ref: https://www.jenkins.io/doc/book/installing/docker/#on-macos-and-linux
FROM jenkins/jenkins:lts-jdk17

USER root
RUN apt-get update && apt-get install -y lsb-release ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# /var/run/docker.sock へ jenkins user がアクセスできるようにするために root group へ追加しています
# jenkins user が root 権限を持ってしまうためセキュリティ上のリスクがあります
# もし root group への追加を行わないと下記のエラーが発生します
# permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.51/containers/node:24.11.0-alpine3.22/json": dial unix /var/run/docker.sock: connect: permission denied

# jenkins user を docker group へ追加する対応へ変更したとしても
# - jenkins container: /var/run/docker.sock の gid
# - host macos : /var/run/docker.sock の gid
# が異なるためエラーになります. そのため root group へ仕方なくいれています
# https://qiita.com/shiojojo/items/e5ac5a7ca5cfd860c1e7
RUN gpasswd -a jenkins root

USER jenkins
COPY jenkins_plugins.txt /usr/share/jenkins/ref/jenkins_plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/jenkins_plugins.txt
