#!/bin/bash

##====================================================================================
## DESCRIPTION: Find apps with high connection counts on shared tenant databases
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

# m4_ignore(
  echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
  exit 11  
#)
# ARG_POSITIONAL_SINGLE([shared_tenant_database_name])
# ARG_OPTIONAL_SINGLE([context], [c], [Specify kubectl context], [current-context])
# ARG_OPTIONAL_SINGLE([threshold], [t], [Connection count threshold], [20])
# ARG_OPTIONAL_SINGLE([output], [o], [Output format (table or json)], [table])
# ARG_HELP([shared-tenant-high-connections], [Get a list of apps with high connection counts to a given shared tenant database])
# ARGBASH_GO

# [ <-- needed because of Argbash

# Dependency check
if ! command -v jq &> /dev/null
then
  echo "Required dependency jq not found"
  print_help
  exit 1
fi

if ! command -v curl &> /dev/null
then
  echo "Required dependency curl not found"
  print_help
  exit 1
fi

if ! command -v psql &> /dev/null
then
  echo "Required dependency psql not found"
  print_help
  exit 1
fi


##============================================
## Main Functionality
##============================================

stname=$_arg_shared_tenant_database_name
ctx=$_arg_context
threshold=$_arg_threshold
outputfmt=$_arg_output

if [ "$ctx" = "current-context" ]; then
  ctx=`kubectl config current-context`
fi

echo -e "${yellow}Getting connection counts over ${reset}$threshold${yellow} for ${reset}$stname${yellow} in ${reset}$ctx${yellow}...${reset}"

# Get shared tenant DB url
stdb=`kubectl --context $ctx get configmap -n akkeris-system database-broker -o json | jq ".data[] | select(test(\".*@${stname}[.].*\"))" -r`

if [ -z "$stdb" ]; then
 echo "${red}✗${reset} Connection URL for $stname not found!"
 exit 1
fi

# database-broker database URL
brokerdb=`kubectl --context $ctx get configmap -n akkeris-system database-broker -o jsonpath='{.data.DATABASE_URL}'`

# controller-api database URL
controllerdb=`kubectl --context $ctx get configmap -n akkeris-system controller-api -o jsonpath='{.data.DATABASE_URL}'`

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

# ] <-- needed because of Argbash