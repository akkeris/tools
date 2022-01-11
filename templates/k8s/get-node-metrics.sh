#!/bin/bash

##====================================================================================
## DESCRIPTION: Script to get CPU and memory of all pods on a given Kubernetes node
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

# m4_ignore(
  echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
  exit 11  
#)
# ARG_OPTIONAL_SINGLE([context], [c], [Specify kubectl context], [current-context])
# ARG_POSITIONAL_SINGLE([node], [Target node])
# ARG_DEFAULTS_POS
# ARG_HELP([get-node-metrics], [Get CPU and memory of all pods on a given Kubernetes node])
# ARGBASH_GO

# [ <-- needed because of Argbash

# Dependency checks
if ! command -v kubectl &> /dev/null
then
  echo "Required dependency kubectl not found"
  echo ""
  print_help
  exit 1
fi

if ! command -v jq &> /dev/null
then
  echo "Required dependency jq not found"
  echo ""
  print_help
  exit 1
fi

if ! command -v curl &> /dev/null
then
  echo "Required dependency curl not found"
  print_help
  exit 1
fi

ctx=$_arg_context
node=$_arg_node

if [ "$ctx" = "current-context" ]; then
  ctx=`kubectl config current-context`
fi

##============================================
## Main Functionality
##============================================

# Does node exist?
if ! kubectl get node $node >/dev/null 2>&1
then
  printf "$red"
  echo "Could not find node named $reset$node"
  echo ""
  print_help
  exit 1
fi

# Create connection to kube apiserver
kubectl --context $ctx proxy --port=8080 --append-server-path >/dev/null 2>&1 &
bg_pid=$!

sleep 2

curl http://localhost:8080/api/v1/nodes/$node/proxy/stats/summary 2>/dev/null | \
	jq '["Pod", "Namespace", "Memory(bytes)", "CPU(cores)"], (.pods[] | [.podRef.name, .podRef.namespace, (.memory.usageBytes/1000000 + 0.5 | floor |tostring + "MB"), (.cpu.usageNanoCores/1000000 + 0.5 | floor | tostring + "m")]) | @tsv' -r | \
	column -t | \
	(read -r; printf "%s\n" "$REPLY"; sort -k3 -nr)

# Kill kube proxy
kill $bg_pid

# ] <-- needed because of Argbash
