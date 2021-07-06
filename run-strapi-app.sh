#!/usr/bin/env bash
set -e
set -m

STRAPI_FOLDER=strapi
PROJECT=getstarted
if [[ ! -d $STRAPI_FOLDER/$PROJECT ]] ; then
  mkdir -p $STRAPI_FOLDER
  cd $STRAPI_FOLDER
  yarn create strapi-app $PROJECT --quickstart --no-run
  cd ..
fi

# copy server.js with URL set
cp strapi-custom/server.js $STRAPI_FOLDER/$PROJECT/config/server.js
# copy SSO provider bootstrap.js with CAS defaults changed for this test deployment
mkdir -p $STRAPI_FOLDER/$PROJECT/extensions/users-permissions/config/functions
cp strapi-custom/bootstrap.js $STRAPI_FOLDER/$PROJECT/extensions/users-permissions/config/functions

cd $STRAPI_FOLDER/$PROJECT
yarn install
# copy over user-permissions-actions.js b/c bootstrap.js references it by relative path
cp ./node_modules/strapi-plugin-users-permissions/config/users-permissions-actions.js extensions/users-permissions/config

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

