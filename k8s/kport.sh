#!/bin/bash

##====================================================================================
## DESCRIPTION: Script to forward a local port to a Kubernetes pod
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

# Color functions
red=$(eval "tput setaf 1")
green=$(eval "tput setaf 2")
yellow=$(eval "tput setaf 3")
reset=$(eval "tput sgr0")

# Usage statement
function usage() {
  echo "Forward local port to a Kubernetes pod"
  echo ""
  echo "Usage: kport [search term] [source_port] [target_port]"
  echo "  -n    Kubernetes namespace (default akkeris-system)"
  echo "  -c    Specify kubectl context (optional)"
  echo "  -h    Show usage"
  echo ""
  echo "Example: kport controller-api 8080 80 -c maru -n akkeris-system"
  
  if [ -n "$1" ]; then
    echo -e "\n${red}$1${reset}";
  fi
  
  exit 1
}

if [ "$#" -lt 3 ]; then
  usage "Search term, source port, and target port required"
fi

if [[ $1 =~ ^-.$ ]] || [[ $2 =~ ^-.$ ]] || [[ $3 =~ ^-.$ ]]; then
  usage "Options must be specified after arguments"
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
sourceport=$2
targetport=$3
shift
shift
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

# kubectl --context=$1 port-forward -n $2 $POD $4:$5

pod=""

echo -e "Searching for pods matching \"$name\" in $ns/$ctx"

searchcmd="kubectl --context=$ctx get pods -n $ns -o=name | grep $name | grep -v worker"
podlist=(`eval $searchcmd`)

if [ ${#podlist[@]} -lt 1 ]
  then
    # No pods exist that match search term
    echo -e "\n${red}✗${reset} No pods matching \"$name\" found in the \"$ns\" namespace."
    exit 1
elif [ ${#podlist[@]} -gt 1 ]
  then
    echo -e "${yellow}Multiple pods found, please select one from the list below:${reset}\n"
    select choice in ${podlist[@]}; do
      pod="${choice}"
      break
    done
    echo
else
  pod="${podlist[0]}"
fi

echo -e "${yellow}Forwarding local port ${sourceport} to port ${targetport} on ${pod}...${reset}\n"

kubectl --context=$ctx port-forward -n $ns $pod $sourceport:$targetport
