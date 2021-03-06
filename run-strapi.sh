#!/usr/bin/env bash
set -e
set -m
FORK=${1:-hdeadman}
REPO=https://github.com/$FORK/strapi.git
BRANCH=${2:-cas2}
STRAPI_FOLDER=strapi

if [[ ! -d $STRAPI_FOLDER ]] ; then
  git clone $REPO --depth 1 --branch $BRANCH $STRAPI_FOLDER
else
  pushd $STRAPI_FOLDER && git pull origin $BRANCH && popd
fi

# copy server.js with URL set
cp server.js $STRAPI_FOLDER/examples/getstarted/config/server.js

cd $STRAPI_FOLDER
yarn setup
cd examples/getstarted

# run without SSL verification in order to call CAS via https
NODE_TLS_REJECT_UNAUTHORIZED=0 yarn develop &
pid=$!
if [[ "$CI" != "true" ]]; then
  fg 1
else
  echo "Waiting for Strapi start up"
  until curl -k -L --output /dev/null --silent --fail http://localhost:1337; do
    echo -n '.'
    sleep 1
  done
  echo "Strapi Ready - PID: $pid"
fi

