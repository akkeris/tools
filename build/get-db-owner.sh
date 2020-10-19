#!/bin/bash

##====================================================================================
## DESCRIPTION: Find the "owner" application of a database given a database name
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

#
# ARG_POSITIONAL_SINGLE([database_name])
# ARG_OPTIONAL_SINGLE([context],[c],[Specify kubectl context],[current-context])
# ARG_HELP([get-db-owner],[Find the owner application of a given database])
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
	local first_option all_short_options='ch'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_context="current-context"


print_help()
{
	printf '%s\n' "get-db-owner"
	printf 'Usage: %s [-c|--context <arg>] [-h|--help] <database_name>\n' "${0##*/}"
	printf '\t%s\n' "-c, --context: Specify kubectl context (default: 'current-context')"
	printf '\t%s\n' "-h, --help: Prints help"
	printf '\n%s\n' "Find the owner application of a given database"
}


parse_commandline()
{
	_positionals_count=0
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
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
	local _required_args_string="'database_name'"
	test "${_positionals_count}" -ge 1 || _PRINT_HELP=yes die "FATAL ERROR: Not enough positional arguments - we require exactly 1 (namely: $_required_args_string), but got only ${_positionals_count}." 1
	test "${_positionals_count}" -le 1 || _PRINT_HELP=yes die "FATAL ERROR: There were spurious positional arguments --- we expect exactly 1 (namely: $_required_args_string), but got ${_positionals_count} (the last one was: '${_last_positional}')." 1
}


assign_positional_args()
{
	local _positional_name _shift_for=$1
	_positional_names="_arg_database_name "

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


# Dependencies

if ! command -v kubectl &> /dev/null
then
  usage "Required dependency kubectl not found"
fi

if ! command -v jq &> /dev/null
then
  usage "Required dependency jq not found"
fi

if ! command -v grep &> /dev/null
then
  usage "Required dependency grep not found"
fi

if ! command -v psql &> /dev/null
then
  usage "Required dependency psql not found"
fi

##============================================
## Main Functionality
##============================================

dbname=$_arg_database_name
ctx=$_arg_context

if [ "$ctx" = "current-context" ]; then
  ctx=`kubectl config current-context`
fi

broker_db_url=`kubectl --context=$ctx get configmap -n akkeris-system database-broker -o jsonpath='{.data.DATABASE_URL}'`
controller_db_url=`kubectl --context=$ctx get configmap -n akkeris-system controller-api -o jsonpath='{.data.DATABASE_URL}'`

service_id=`psql ${broker_db_url} -c "select id from databases where name = '$dbname' and deleted = false" -t | tr -d '[:space:]'`

if [ -z "$service_id" ]
then
  echo "${red}✗${reset} Valid database with name $dbname not found"
  exit 1
fi

psql $controller_db_url -t -c \
"select \
  concat(apps.name,'-',spaces.name) as appname \
from service_attachments \
  join apps on apps.app = service_attachments.app \
  join spaces on apps.space = spaces.space \
where \
  service_attachments.deleted = false \
  and apps.deleted = false \
  and service_attachments.owned = true \
  and service_attachments.service = '${service_id}'"

# ] <-- needed because of Argbash
