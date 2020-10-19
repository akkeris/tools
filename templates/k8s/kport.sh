#!/bin/bash

##====================================================================================
## DESCRIPTION: Script to forward a local port to a Kubernetes pod
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

# m4_ignore(
  echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
  exit 11  
#)
# ARG_OPTIONAL_SINGLE([namespace], [n], [Specify kubernetes namespace], [akkeris-system])
# ARG_OPTIONAL_SINGLE([context], [c], [Specify kubectl context], [current-context])
# ARG_POSITIONAL_SINGLE([pod], [Search term for target pod (e.g. controller-api)])
# ARG_POSITIONAL_SINGLE([source_port], [Port to listen on locally])
# ARG_POSITIONAL_SINGLE([target_port], [Port to forward in the pod])
# ARG_DEFAULTS_POS
# ARG_HELP([kport], [Forward a local port to a Kubernetes pod found via search])
# ARGBASH_GO

# [ <-- needed because of Argbash

if ! command -v kubectl &> /dev/null
then
  usage "Required dependency kubectl not found"
fi

if ! command -v grep &> /dev/null
then
  usage "Required dependency grep not found"
fi

ns=$_arg_namespace
ctx=$_arg_context
name=$_arg_pod
sourceport=$_arg_source_port
targetport=$_arg_target_port

if [ "$ctx" = "current-context" ]; then
  ctx=`kubectl config current-context`
fi

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

# ] <-- needed because of Argbash
