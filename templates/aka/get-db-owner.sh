#!/bin/bash

##====================================================================================
## DESCRIPTION: Find the "owner" application of a database given a database name
## AUTHOR: Sam Beckett (@sbeck14)
##====================================================================================

# m4_ignore(
  echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
  exit 11  
#)
# ARG_POSITIONAL_SINGLE([database_name])
# ARG_OPTIONAL_SINGLE([context], [c], [Specify kubectl context], [current-context])
# ARG_HELP([get-db-owner], [Find the owner application of a given database])
# ARGBASH_GO

# [ <-- needed because of Argbash

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
