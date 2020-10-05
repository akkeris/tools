#!/bin/bash

##====================================================================================
## DESCRIPTION: Script to delete multiple kubernetes pods via grep ("bounce" them)
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

# Color functions
red=$(eval "tput setaf 1")
green=$(eval "tput setaf 2")
yellow=$(eval "tput setaf 3")
reset=$(eval "tput sgr0")

# Usage statement
function usage() {
  echo "Restart multiple Kubernetes pods based on a grep search"
  echo ""
  echo "Usage: kbounce [search term]"
  echo "  -n    Kubernetes namespace (default akkeris-system)"
  echo "  -c    Specify kubectl context (optional)"
  echo "  -h    Show usage"
  echo ""
  echo "Example: kbounce controller-api -c maru -n akkeris-system"
  
  if [ -n "$1" ]; then
    echo -e "\n${red}$1${reset}";
  fi
  
  exit 1
}

if [ "$#" -lt 1 ]; then
  usage "Search term required"
fi

if [[ $1 =~ ^-.$ ]]; then
  usage "Search term must come first"
fi

if ! command -v kubectl &> /dev/null
then
  usage "Required dependency kubectl not found"
fi

if ! command -v grep &> /dev/null
then
  usage "Required dependency grep not found"
fi

ns="akkeris-system"
ctx=`kubectl config current-context`
name=$1
shift

# Process command-line options
while getopts ":n:c:h" opt; do
  case ${opt} in
    n ) # process namespace
      ns="$OPTARG"
      ;;
    c ) # process context
      ctx="$OPTARG"
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

echo -e "Searching for pods matching \"$name\" in $ns/$ctx"

searchcmd="kubectl --context $ctx get pods -n $ns -o name | grep $name"
podlist=(`eval $searchcmd`)

if [ ${#podlist[@]} -lt 1 ]
  then
    # No pods exist that match search term
    echo -e "\n${red}✗${reset} No pods matching \"$name\" found in the \"$ns\" namespace."
    exit 1
  else 
    # Found pods. Print them to the user and ask for confirmation
    echo -e "${yellow}Do you really want to delete the following pods?${reset}\n"
    for el in ${podlist[@]}
      do
        echo -e "  • $el"
    done
    echo ""
    select choice in "Yes" "No"
      do
        case $choice in
          Yes )
            echo -e "\n${red}Deleting pods...${reset}";
            kubectl --context $ctx delete -n $ns ${podlist[*]}
            podlist=(`eval $searchcmd`)
            echo -e "\n${green}New pods:${reset}"
            for el in ${podlist[@]}
              do
                echo -e "  • $el"
            done
          break;;
          No ) echo -e "\n${yellow}Cancelling...${reset}"; break;;
        esac
    done
fi