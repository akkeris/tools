#!/bin/bash

##====================================================================================
## DESCRIPTION: Find apps with high connection counts on shared tenant databases
## AUTHOR: Sam Beckett (@sbeck14)
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
  echo "Find apps with high connection counts on shared tenant databases"
  echo ""
  echo "Usage: st-high-connections [database name]"
  echo "  -c    Specify kubectl context (optional, default current-context)"
  echo "  -t    Connection count threshold (optional, default 20)"
  echo "  -o    Output format (optional, default table. options: table, json)"
  echo "  -h    Show usage"
  echo ""
  echo "Example: st-high-connections hobbydb -c ds1 -t 25"
  
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
  usage "Database name required"
fi

if [[ $1 =~ ^-.*$ ]]; then
  usage "Database name must come before options"
fi

# Dependency check
if ! command -v jq &> /dev/null
then
  usage "Required dependency jq not found"
fi

if ! command -v curl &> /dev/null
then
  usage "Required dependency curl not found"
fi

if ! command -v psql &> /dev/null
then
  usage "Required dependency psql not found"
fi

ctx=`kubectl config current-context`
outputfmt="table"
threshold=20
stname=$1
shift

# Process command-line options
# See getopts documentation for more info
while getopts ":o:t:c:h" opt; do
  case ${opt} in
    o ) # process output format
      outputfmt="$OPTARG"
      ;;
    t ) # process threshold
      threshold="$OPTARG"
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

echo -e "${yellow}Getting connection counts over ${reset}$threshold${yellow} for ${reset}$stname${yellow} in ${reset}$ctx${yellow}...${reset}"

# Get shared tenant DB url
stdb=`kubectl --context $ctx get configmap -n akkeris-system database-broker -o json | jq ".data[] | select(test(\".*@${stname}[.].*\"))" -r`

if [ -z "$stdb" ]; then
 echo "${red}✗${reset} Connection URL for $stname not found!"
 exit 1
fi

# database-broker database URL
brokerdb=`kubectl --context $ctx get configmap -n akkeris-system database-broker -o json | jq '.data.DATABASE_URL' -r`

# controller-api database URL
controllerdb=`kubectl --context $ctx get configmap -n akkeris-system controller-api -o json | jq '.data.DATABASE_URL' -r`

# Get connection counts over $threshold in the shared tenant database
connection_counts=`psql $stdb -t -c "
select
  array_to_json(array_agg(row_to_json(t)))
from (
  select
    datname as dbname,
    count(datname) as count
  from pg_stat_activity
  group by dbname
  order by count desc
) as t
where t.count >= $threshold"`

if [ -z "$connection_counts" ]; then
  echo "${red}✗${reset} No connections above the threshold of $threshold were found!"
  exit 1
fi

# Get database service IDs from the database-broker
joinednames=`echo $connection_counts | jq "[.[].dbname] | join(\"' or name='\")" -r`
namesquery="name='$joinednames'"
names_and_ids=`psql ${brokerdb} -t -c  "
select 
  array_to_json(array_agg(row_to_json(t)))
from (
  select
    name as dbname, 
    id as dbid
  from databases 
  where ${namesquery}
) as t"`

# Combine the names, counts, and service IDs
names_ids_counts=`jq -n --argjson a1 "$names_and_ids" --argjson a2 "$connection_counts" -s '[(\$a1 + \$a2 | group_by(.dbname)) | .[] | add]'`

# Get app names from the controller-api
joinedids=`echo $names_ids_counts | jq "[.[].dbid] | join(\"' or service_attachments.service='\")" -r`
idsquery="(service_attachments.service='$joinedids')"
appnames=`psql $controllerdb -t -c "
select 
  array_to_json(array_agg(row_to_json(t)))
from (
  select
    service_attachments.service as dbid,
    concat(apps.name,'-',spaces.name) as appname
  from service_attachments
    join apps on apps.app = service_attachments.app
    join spaces on apps.space = spaces.space
  where 
    service_attachments.deleted = false
    and apps.deleted = false
    and service_attachments.owned = true
    and ${idsquery}
) as t" | tr -d '[:space:]'`

# Combine the names, counts, service IDs, and app names
all_info=`jq -n --argjson a1 "$names_ids_counts" --argjson a2 "$appnames" -s '[(\$a1 + \$a2 | group_by(.dbid)) | .[] | add] | [ sort_by(.count) | reverse[] ]'`

case $outputfmt in
  "json")
    echo $all_info | jq '.'
    ;;
  "table")
    echo $all_info | jq '(["Appname","Connections", "Database"] | (., map(length*"-"))), (.[] | [.appname, .count, .dbname]) | @tsv' -r | column -t
    ;;
  *)
    echo "${red}✗${reset} Output format not recognized. Using json instead."
    echo $all_info | jq '.'
    ;;
esac