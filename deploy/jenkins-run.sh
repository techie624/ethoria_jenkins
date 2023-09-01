#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
#@author: rpetrie (techie624@gmail.com)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

set -e # Abort script at first error
set -u # Attempt to use undefined variable outputs error message
set -x # Verbose with commands displayed

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

source ./vars

echo "BUILD_TAG is set as: $BUILD_TAG";
echo;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Remove any jenkins/jenkins:latest images

docker rm -f jenkins-node

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Remove images (this will fail if running container is using an image)

docker rmi $(docker images -a -q) || true;
echo;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# running jenkins image build

GID=$(cut -d: -f3 < <(getent group docker))

time docker image build --build-arg GID=$GID -t $DOCKER_HUB_USERNAME/$DOCKER_HUB_REPO_NAME:$BUILD_TAG .
echo;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Remove any jenkins/jenkins:latest images used for build

docker rmi -f jenkins/jenkins:latest || true;
echo;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
### set present working directory (jenkins repo) as jenkins_home

cd ..
pwd=$(pwd) && echo $pwd

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
### Run Jenkins

docker run -dti \
--name jenkins-node \
-h jenkins-node \
-v $pwd:/var/jenkins_home \
-v ~/.ssh:/var/jenkins_home/.ssh \
-v /var/run/docker.sock:/var/run/docker.sock \
-p $JENKINS_EXT_PORT:8080 \
--restart=always \
$DOCKER_HUB_USERNAME/$DOCKER_HUB_REPO_NAME:$BUILD_TAG
echo;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
### On initial setup display initialAdminPassword

sleep 3

docker exec -u root jenkins-node bash -c '
FILE="/var/jenkins_home/secrets/initialAdminPassword"
if [[ -f "$FILE" ]]; then
   echo "Please Copy the following line into localhost:8080"
   cat /var/jenkins_home/secrets/initialAdminPassword
   echo;
fi';
echo;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
### Script completion

echo "Jenkins Deployment script has completed! Good Bye."
echo;
