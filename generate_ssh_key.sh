#!/bin/bash

PRIVATE_KEY="jenkins_ssh_agent_key"
PUBLIC_KEY="${PRIVATE_KEY}.pub"
ENV_FILE=".env"


if [ -f $PRIVATE_KEY ]; then
    exit 0
fi

ssh-keygen -t ed25519 -f $PRIVATE_KEY -N ""

if [ ! -f $ENV_FILE ]; then
    touch .env
fi

KEY=$(cat $PUBLIC_KEY)
echo "JENKINS_AGENT_SSH_PUBKEY=$KEY" >> .env
