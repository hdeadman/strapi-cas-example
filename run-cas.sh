#!/usr/bin/env bash

# set variables related to path handling on windows msys/msys2
export MSYS2_ARG_CONV_EXCL="*"
export MSYS_NO_PATHCONV=1

CAS_VERSION=${1:-6.3.3}
BOOT_VERSION=${2:-2.3.7.RELEASE}
if [[ $CAS_VERSION =~ ^6.3.*$ ]]; then
  export PROFILES=standalone,ldap,ldap63
else
  export PROFILES=standalone,ldap,ldap64
fi
echo "Using CAS version $CAS_VERSION with profiles $PROFILES"

set -e
set -m

if [[ ! -d cas-server-${CAS_VERSION} ]]; then
  ./run-cas-initializr.sh $CAS_VERSION $BOOT_VERSION
  # use heroku deployed cas-initializr to in
  #mkdir cas-server-${CAS_VERSION}
  #cd cas-server-${CAS_VERSION}
  #curl https://casinit.herokuapp.com/starter.tgz -d "dependencies=oidc,ldap,jsonsvc&casVersion=${CAS_VERSION}&bootVersion=${BOOT_VERSION}" | tar  -xzvf -
fi
cd cas-server-${CAS_VERSION}

echo "Copying CAS service for strapi to JSON service registry folder"
# config/temp is for regression in spring boot 2.5.0, remove in 2.5.1
mkdir -p config services logs config/temp
cp -f ../services/* services
echo "Copying ldap config info config folder"
cp -f ../ldap/application-*.properties config

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
ls -l build/libs/
java -Dlog4j.configurationFile=./etc/cas/config/log4j2.xml -jar build/libs/app.war \
	--server.ssl.key-store=thekeystore \
  --spring.profiles.active=${PROFILES} \
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
echo "PID is ${pid}"
if [[ "$CI" != "true" ]]; then
  fg 1
else
  echo "Waiting for CAS to start up"
  sleep 5
  echo "Checking for PID ${pid}"
  ps -ef | grep $pid
  until curl -k -L --output /dev/null --silent --fail https://localhost:8443/cas/login; do
    echo -n '.'
    sleep 1
  done
  echo "CAS Ready - PID: $pid"
fi
