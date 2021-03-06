#!/bin/bash

function checkTool() {
  local TOOL=$1
  echo Checking $TOOL
  command -v $TOOL > /dev/null
  if [[ $? -ne 0 ]] ; then
    echo $TOOL not found in path
  fi
}

checkTool git
checkTool java
checkTool javac
checkTool yarn
checkTool node
checkTool docker
checkTool curl

echo Java version should be 11+
java -version
echo Node version is $(node --version)


