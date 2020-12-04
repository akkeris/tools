#!/bin/bash

# Make sure to set your kubectl context before 'source'ing this file!!

export JWT_PRIVATE_KEY=`kubectl get cm -n akkeris-system controller-api -o jsonpath="{.data.JWT_RS256_PRIVATE_KEY}"`
export JWT_RS256_PUBLIC_CERT=`kubectl get cm -n akkeris-system controller-api -o jsonpath="{.data.JWT_RS256_PUBLIC_CERT}"`