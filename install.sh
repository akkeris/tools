#!/bin/bash

# Copy built scripts to /usr/local/bin

SCRIPTS=`find build -type f`

if [ -z "$SCRIPTS" ]; then
  echo "Please run \"build.sh\" before running the install script."
  exit 1
fi

for script in $SCRIPTS
do
  scriptname=`basename $script .sh`
  cp $script /usr/local/bin/$scriptname
done