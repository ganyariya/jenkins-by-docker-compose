# jenkins-by-docker-compose

This is a sample for building a Jenkins environment using docker compose.
You can create the following Jenkins environment:

- Jenkins Controller
  - You can install your favorite plugins from `jenkins_plugins.txt`
  - The default `jenkins_plugins.txt` installs the following plugins:
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

If you have Jenkins plugins you want to install from the beginning, add the plugin names to `jenkins-controller/jenkins_plugins.txt`.

```bash
cat jenkins-controller/jenkins_plugins.txt
blueocean
# https://plugins.jenkins.io/job-dsl/
job-dsl
# https://docs.cloudbees.com/docs/cloudbees-ci/latest/pipelines/docker-workflow
docker-workflow

# please write your favorite jenkins plugins below, when docker compose build
```

Next, generate the ssh key for connecting with SSH agent nodes, build the images, and start the services.

```bash
# generate ssh key & create .env file
sh generate_ssh_key.sh

# build images & activate jenkins
docker compose up -d
```

After `docker compose up -d` completes, open `http://localhost:8080`.
Jenkins should be running.

From here, you'll perform various configurations using the Jenkins Web Console.
Please refer to the [Setup Guide](./setup-guide/README.md).

## Tested Environment

| environment            | status |
| ---------------------- | ------ |
| Docker Desktop for Mac | ✅️      |