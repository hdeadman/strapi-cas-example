#!/usr/bin/env bash

# set variables related to path handling on windows msys/msys2
export MSYS2_ARG_CONV_EXCL="*"
export MSYS_NO_PATHCONV=1

set -e
set -m

docker stop cas-initializr || true
if [[ ! -d cas-server ]]; then
  echo "Running CAS Intializr to generate CAS Overlay"
  docker run -d --name cas-initializr -it --rm -p9080:8080 apereo/cas-initializr:6.3.0 
  sleep 20
  echo Waiting for CAS initializr container to start
  mkdir cas-server
  cd cas-server
  curl http://localhost:9080/starter.tgz -d dependencies=oidc,ldap,jsonsvc | tar -xzvf -
else
  cd cas-server
fi

echo "Copying CAS service for strapi to JSON service registry folder"
mkdir -p config services logs
cp -f ../services/* services
echo "Copying ldap config info config folder"
cp -f ../ldap/application-ldap.properties config

if [[ ! -f thekeystore ]] ; then
   echo "Create Server SSL keystore"
  ./gradlew -PcertDir=. createKeyStore
fi
echo "Building CAS Server"
./gradlew clean build

if [[ "$1" == "FLAT" ]]; then 
  ATTRIBUTE_STYLE=FLAT
  shift
else
  # default in CAS is NESTED
  ATTRIBUTE_STYLE=NESTED
fi
echo "Using attribute style $ATTRIBUTE_STYLE"

# make logs folder under cas-server
sed -i 's/\/var\/log/.\/logs/g' ./etc/cas/config/log4j2.xml

# Run CAS server using arguments for config rather than property files, make config folders and certs relative to project to avoid needing to use sudo
echo "Running CAS Server"
java -jar build/libs/cas.war \
	--server.ssl.key-store=thekeystore \
  --spring.profiles.active=standalone,ldap \
	--cas.standalone.configuration-directory=./config \
	--cas.service-registry.json.location=file:./services \
	--cas.server.name=https://localhost:8443 \
  --cas.server.prefix='${cas.server.name}/cas' \
  --cas.authn.attribute-repository.stub.attributes.email=casuser@apereo.org \
  --cas.authn.attribute-repository.stub.id=STUB \
	--cas.authn.oidc.jwks.jwks-file=file:./config/keystore.jwks \
  --logging-config=file:./etc/cas/config/log4j2.xml \
  --logging.level.org.apereo.cas=DEBUG \
  --logging.level.org.apereo.services.persondir=DEBUG \
  --cas.authn.oauth.user-profile-view-type=$ATTRIBUTE_STYLE &
pid=$!
if [[ "$CI" != "true" ]]; then
  fg 1
else
  echo "Waiting for CAS to start up"
  until curl -k -L --output /dev/null --silent --fail https://localhost:8443/cas/login; do
    echo -n '.'
    sleep 1
  done
  echo "CAS Ready - PID: $pid"
fi
