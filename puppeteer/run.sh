#!/bin/bash
set -e

npm install
npm run casconnect | tee -a testoutput.log