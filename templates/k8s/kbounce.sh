#!/bin/bash

##====================================================================================
## DESCRIPTION: Script to delete multiple kubernetes pods via grep ("bounce" them)
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

# m4_ignore(
  echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
  exit 11  
#)
# ARG_OPTIONAL_SINGLE([namespace], [n], [Specify kubernetes namespace], [akkeris-system])
# ARG_OPTIONAL_SINGLE([context], [c], [Specify kubectl context], [current-context])
# ARG_POSITIONAL_SINGLE([pod], [Search term for target pod (e.g. controller-api)])
# ARG_DEFAULTS_POS
# ARG_HELP([kport], [Restart multiple Kubernetes pods based on a grep search])
# ARGBASH_GO

# [ <-- needed because of Argbash

# Dependency checks
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

if [ "$ctx" = "current-context" ]; then
  ctx=`kubectl config current-context`
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

# ] <-- needed because of Argbash
