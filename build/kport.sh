#!/bin/bash

##====================================================================================
## DESCRIPTION: Script to forward a local port to a Kubernetes pod
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

#
# ARG_OPTIONAL_SINGLE([namespace],[n],[Specify kubernetes namespace],[akkeris-system])
# ARG_OPTIONAL_SINGLE([context],[c],[Specify kubectl context],[current-context])
# ARG_POSITIONAL_SINGLE([pod],[Search term for target pod (e.g. controller-api)])
# ARG_POSITIONAL_SINGLE([source_port],[Port to listen on locally])
# ARG_POSITIONAL_SINGLE([target_port],[Port to forward in the pod])
# ARG_DEFAULTS_POS()
# ARG_HELP([kport],[Forward a local port to a Kubernetes pod found via search])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.10.0 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
	local _ret="${2:-1}"
	test "${_PRINT_HELP:-no}" = yes && print_help >&2
	echo "$1" >&2
	exit "${_ret}"
}


begins_with_short_option()
{
	local first_option all_short_options='nch'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
_arg_pod=
_arg_source_port=
_arg_target_port=
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_namespace="akkeris-system"
_arg_context="current-context"


print_help()
{
	printf '%s\n' "kport"
	printf 'Usage: %s [-n|--namespace <arg>] [-c|--context <arg>] [-h|--help] <pod> <source_port> <target_port>\n' "$0"
	printf '\t%s\n' "<pod>: Search term for target pod (e.g. controller-api)"
	printf '\t%s\n' "<source_port>: Port to listen on locally"
	printf '\t%s\n' "<target_port>: Port to forward in the pod"
	printf '\t%s\n' "-n, --namespace: Specify kubernetes namespace (default: 'akkeris-system')"
	printf '\t%s\n' "-c, --context: Specify kubectl context (default: 'current-context')"
	printf '\t%s\n' "-h, --help: Prints help"
	printf '\n%s\n' "Forward a local port to a Kubernetes pod found via search"
}


parse_commandline()
{
	_positionals_count=0
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-n|--namespace)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_namespace="$2"
				shift
				;;
			--namespace=*)
				_arg_namespace="${_key##--namespace=}"
				;;
			-n*)
				_arg_namespace="${_key##-n}"
				;;
			-c|--context)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_context="$2"
				shift
				;;
			--context=*)
				_arg_context="${_key##--context=}"
				;;
			-c*)
				_arg_context="${_key##-c}"
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_last_positional="$1"
				_positionals+=("$_last_positional")
				_positionals_count=$((_positionals_count + 1))
				;;
		esac
		shift
	done
}


handle_passed_args_count()
{
	local _required_args_string="'pod', 'source_port' and 'target_port'"
	test "${_positionals_count}" -ge 3 || _PRINT_HELP=yes die "FATAL ERROR: Not enough positional arguments - we require exactly 3 (namely: $_required_args_string), but got only ${_positionals_count}." 1
	test "${_positionals_count}" -le 3 || _PRINT_HELP=yes die "FATAL ERROR: There were spurious positional arguments --- we expect exactly 3 (namely: $_required_args_string), but got ${_positionals_count} (the last one was: '${_last_positional}')." 1
}


assign_positional_args()
{
	local _positional_name _shift_for=$1
	_positional_names="_arg_pod _arg_source_port _arg_target_port "

	shift "$_shift_for"
	for _positional_name in ${_positional_names}
	do
		test $# -gt 0 || break
		eval "$_positional_name=\${1}" || die "Error during argument parsing, possibly an Argbash bug." 1
		shift
	done
}

parse_commandline "$@"
handle_passed_args_count
assign_positional_args 1 "${_positionals[@]}"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash

# Color Functions 
red=$(eval "tput setaf 1") 
green=$(eval "tput setaf 2") 
yellow=$(eval "tput setaf 3") 
reset=$(eval "tput sgr0")


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
