#!/bin/bash

# clean strapi DB
rm -rf strapi/examples/getstarted/.tmp
echo "Strapi DB deleted"
if [[ "$1" == "all" ]] ; then
  rm -rf cas-server
  rm -rf strapi
else
  echo "Run \"$0 all\" to delete CAS overlay and Strapi cloned repo"
fi
