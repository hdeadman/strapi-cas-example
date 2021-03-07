#!/bin/bash

FORK=${1:-hdeadman}
REPO=https://github.com/$FORK/strapi.git
BRANCH=${2:-cas}
STRAPI_FOLDER=${3:-strapi}

if [[ ! -d $STRAPI_FOLDER ]] ; then
  git clone $REPO --depth 1 --branch $BRANCH $STRAPI_FOLDER
else
  pushd $STRAPI_FOLDER 
  git pull origin $BRANCH 
  popd
fi
