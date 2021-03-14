#!/bin/bash
set -e
script=${1:-casconnect}
npm install
npm run $script | tee -a testoutput.log
