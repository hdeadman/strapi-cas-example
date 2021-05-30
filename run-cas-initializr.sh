#!/bin/bash

CAS_VERSION=${1:-6.3.3}
BOOT_VERSION=${2:-2.3.7.RELEASE}

INITIALIZR_DIR=cas-initializr

if [[ ! -d $INITIALIZR_DIR ]]; then
  git clone https://github.com/apereo/cas-initializr.git $INITIALIZR_DIR
  cd $INITIALIZR_DIR
else
  cd $INITIALIZR_DIR
  git pull origin master
fi

source ./ci/functions.sh

echo "Building CAS Initializr"
./gradlew --build-cache --configure-on-demand --no-daemon clean build -x test -x javadoc -x check --parallel

echo "Running initializr"
java -jar app/build/libs/app.jar &
initializr_pid=$!
waitForInitializr

cd ..
mkdir -p cas-server-${CAS_VERSION}
cd cas-server-${CAS_VERSION}
curl http://localhost:8080/starter.tgz -d "dependencies=oidc,ldap,jsonsvc&casVersion=${CAS_VERSION}&bootVersion=${BOOT_VERSION}" | tar  -xzvf -

curl -X POST http://localhost:8081/actuator/shutdown 2> /dev/null || true
cd ..
