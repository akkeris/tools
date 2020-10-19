#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]] && ! command -v gsed &> /dev/null
then 
  echo "If running this script on MacOS, gnu-sed is required."
  echo "Try running 'brew install gnu-sed' and try again."
  exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
  shopt -s expand_aliases
  alias sed="gsed"
fi

# Pull argbash image
docker pull matejak/argbash:2.10.0 1>/dev/null

rm -rf build
mkdir build


# Common helper functions that will be added to scripts
helpers='\
\
# Color Functions \
red=$(eval \"tput setaf 1\") \
green=$(eval \"tput setaf 2\") \
yellow=$(eval \"tput setaf 3\") \
reset=$(eval \"tput sgr0\")'

TEMPLATES=`find templates -type f`
for template in $TEMPLATES
do
  scriptname=`basename $template`
  docker run --rm -v "$(pwd):/work" -u "$(id -u):$(id -g)" matejak/argbash:2.10.0 $template -o "build/$scriptname"
  sed -i "/# \[ <-- needed because of Argbash/a $helpers" build/$scriptname
done






