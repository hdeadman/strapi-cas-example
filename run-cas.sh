#!/usr/bin/env bash

# set variables related to path handling on windows msys/msys2
export MSYS2_ARG_CONV_EXCL="*"
export MSYS_NO_PATHCONV=1

set -e

docker stop cas-initializr || true
if [[ ! -d cas-server ]]; then
  echo "Running CAS Intializr to generate CAS Overlay"
  docker run -d --name cas-initializr -it --rm -p9080:8080 apereo/cas-initializr:6.3.0 
  sleep 20
  echo Waiting for CAS initializr container to start
  mkdir cas-server
  cd cas-server
  curl http://localhost:9080/starter.tgz -d dependencies=oidc,jsonsvc | tar -xzvf -
else
  cd cas-server
fi

echo "Copying CAS service for strapi to JSON service registry folder"
mkdir -p config services
cp ../services/* services

if [[ ! -f thekeystore ]] ; then
   echo "Create Server SSL keystore"
  ./gradlew -PcertDir=. createKeyStore
fi
echo "Building CAS Server"
./gradlew clean build

if [[ "$1" == "FLAT" ]]; then 
  FLAG_ARG=--cas.authn.oauth.user-profile-view-type=FLAT
  shift
else
  FLAT_ARG=
fi

# Run CAS server
echo "Running CAS Server"
java -jar build/libs/cas.war --server.ssl.key-store=thekeystore --cas.standalone.configuration-directory=./config --cas.service-registry.json.location=file:./services --cas.server.name=https://localhost:8443 --cas.server.prefix='${cas.server.name}/cas' --cas.authn.attribute-repository.stub.attributes.email=casuser@apereo.org $FLAT_ARG

#--cas.authn.attribute-repository.default-attributes-to-release=uid,username,email --cas.authn.oidc.claims=username,email
