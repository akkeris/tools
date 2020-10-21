#!/bin/bash

# Need gnu-sed which is not included on MacOS
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

# Dependency check
if ! command -v docker &> /dev/null
then
  usage "Required dependency docker not found"
fi

# Pull argbash image if not present
if ! $(docker image inspect matejak/argbash:2.10.0 > /dev/null 2>&1); then
  docker pull matejak/argbash:2.10.0 1>/dev/null
fi

# Remove old build files
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

# Get list of template files in the template folder
TEMPLATES=`find templates -type f`

for template in $TEMPLATES
do
  scriptname=`basename $template`
  
  # Build template with argbash
  docker run --rm -v "$(pwd):/work" -u "$(id -u):$(id -g)" matejak/argbash:2.10.0 $template -o "build/$scriptname"
  
  # Add helper functions 
  sed -i "/# Argbash is FREE SOFTWARE, see https:\/\/argbash.io for more info/a $helpers" build/$scriptname

  # Replace "$0" with "${0##*/}"
  sed -i 's/\"\$0\"/\"\$\{0##*\/\}\"/g' build/$scriptname

  # Replace "FATAL ERROR:" with a red x
  sed -i 's/FATAL ERROR:/\n${red}✗${reset}/g' build/$scriptname
done
