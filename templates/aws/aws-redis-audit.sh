#!/bin/bash

##====================================================================================
## DESCRIPTION: Script that finds orphaned Redis resources in AWS
## AUTHOR: Trevor Linton (@trevorlinton)
##====================================================================================

# m4_ignore(
  echo "This is just a script template, not the script (yet) - pass it to 'argbash' to fix this." >&2
  exit 11  
#)
# ARG_OPTIONAL_SINGLE([context], [c], [Specify kubectl context], [current-context])
# ARG_HELP([Find a list of Redis resources in AWS that are not attached to either the database-broker or controller-api])
# ARGBASH_GO

# [ <-- needed because of Argbash

CLUSTER=$_arg_context

if [ "$CLUSTER" = "current-context" ]; then
  CLUSTER=`kubectl config current-context`
fi

aws elasticache describe-cache-clusters --max-items 200 > clusters.json
jq -r '.CacheClusters[] | select ( .Engine == "redis" ).CacheClusterId' clusters.json > redis-caches.txt
DEFINITIONS=`kubectl get deployments --all-namespaces -o yaml --context $CLUSTER`
ELASTICACHE_DATABASE=`kubectl get configmaps/elasticache-broker -o jsonpath='{.data.DATABASE_URL}' -n akkeris-system --context $CLUSTER`
CONTROLLER_API_DATABASE=`kubectl get configmaps/controller-api -o jsonpath='{.data.DATABASE_URL}' -n akkeris-system --context $CLUSTER`
rm not-found-in-cluster.txt
while read p; do
  OUT=`echo $DEFINITIONS | grep $p`
  if [ "$OUT" == "" ]; then
      echo "$p" >> not-found-in-cluster.txt
  fi
done <redis-caches.txt

rm not-found-in-elasticache-broker.txt >> /dev/null
rm found-in-elasticache-broker.txt
while read p; do 
    SERVICE_ID=`echo "select id from resources where name='$p'" | psql $ELASTICACHE_DATABASE -A -q -t`
    if [ "$SERVICE_ID" == "" ]; then
        echo "$p" >> not-found-in-elasticache-broker.txt
    else 
        echo "$SERVICE_ID" >> found-in-elasticache-broker.txt
    fi
done <not-found-in-cluster.txt

rm not-found-in-app-controller.txt
rm found-in-app-controller.txt
while read p; do
    IS_VALID=`echo "select apps.app from services join service_attachments on services.service = service_attachments.service join apps on service_attachments.app = apps.app where services.service = '$p' and services.deleted = false and service_attachments.deleted = false and apps.deleted = false" | psql $CONTROLLER_API_DATABASE -A -q -t`
    if [ "$IS_VALID" == "" ]; then
        echo "$p" >> not-found-in-app-controller.txt
    else
        echo "$p" >> found-in-app-controller.txt
    fi
done <found-in-elasticache-broker.txt

# ] <-- needed because of Argbash
