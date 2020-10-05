#!/bin/bash

# This is a template you can use for writing bash scripts
# It includes some helpful functions that you may find useful

##====================================================================================
## DESCRIPTION: Description of script
## AUTHOR: Name (@username)
##====================================================================================

##============================================
## Helper Functions
##============================================

# Color functions
# Useful for changing the color of displayed text
# Example: echo -e "${red}WARNING${reset}"
red=$(eval "tput setaf 1")
green=$(eval "tput setaf 2")
yellow=$(eval "tput setaf 3")
reset=$(eval "tput sgr0")

# Usage statement
# Prints information on how to use the script, including arguments and options
function usage() {
  echo "Script description"
  echo ""
  echo "Usage: script_name [argument]"
  echo "  -o    Option description"
  echo "  -h    Show usage"
  echo ""
  echo "Example: script_name argument -o option"
  
  if [ -n "$1" ]; then
    echo -e "\n${red}$1${reset}";
  fi
  
  exit 1
}

# Show usage statement if -h is first argument
if [ "$1" == "-h" ]; then
  usage
fi

# Check for required arguments
if [ "$#" -lt 1 ]; then
  usage "Argument required"
fi

if [[ $1 =~ ^-.*$ ]]; then
  usage "Argument must come before options"
fi


# Dependency check
if ! command -v grep &> /dev/null
then
  usage "Required dependency grep not found"
fi

opt1="default value for option o"

# Process command-line options
# See getopts documentation for more info
while getopts ":o:h" opt; do
  case ${opt} in
    o ) # process option "o"
      opt1="$OPTARG"
      ;;
    h ) # show help
      usage
      ;;
    \? ) # process invalid options
      usage "-$OPTARG is not a valid option"
      ;;
    : ) # process invalid argument to an option
      usage "-$OPTARG requires an argument"
      ;;
  esac
done
shift $((OPTIND -1))

if [ "$#" -gt 0 ]; then
  usage "Extra arguments are not allowed"
fi

##============================================
## Main Functionality
##============================================

# Now you can write your script here.