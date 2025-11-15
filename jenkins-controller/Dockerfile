# ref: https://www.jenkins.io/doc/book/installing/docker/#on-macos-and-linux
FROM jenkins/jenkins:lts-jdk21

USER root
# install docker for docker-workflow plugin
RUN apt-get update && apt-get install -y lsb-release ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/debian $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# On Docker Desktop for Mac, `/var/run/docker.sock` permission of container is root user & root group.
# Therefore, jenkins user cannot use `/var/run/docker.sock` in docker pipeline plugin.
# So, jenkins user is joined to root group.
RUN gpasswd -a jenkins root

USER jenkins
COPY jenkins_plugins.txt /usr/share/jenkins/ref/jenkins_plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/jenkins_plugins.txt
