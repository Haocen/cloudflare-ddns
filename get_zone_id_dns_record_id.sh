#!/bin/bash

api_token="$API_TOKEN"		# cloudflare api token, do not include "Bearer"
domain="$DOMAIN"
host="$HOST"		# optional
debug=""

if [ -z "$api_token" ]; then
  echo "Please input the api_token you want to use, it must has permission to list zones:"
  read api_token
fi

if [ -z "$domain" ]; then
  echo "Please input the domain you want to query:"
  read domain
fi

if [ ! -z "$host" ]; then
  optional_name_parameter_querystring="?name=$host.$domain"
fi

echo "Trying to find zone_id and dns_record_id for $host.$domain"

if [[ "${DEBUG,,}" == "true" || "${DEBUG,,}" == "yes" ]]; then
	debug="true"
fi

auth_header="Authorization: Bearer $api_token"

if [ ! -z "$debug" ]; then
	echo "Authorization header:"
	echo "$auth_header"
fi

echo ""
echo "Making request to list zones"
echo ""

get_zone_id_result=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
  -H "$auth_header" \
  -H "Content-Type: application/json")

if [ ! $? -eq 0 ]; then
	echo "Failed to list zones"
	echo "$get_zone_id_result"
	exit 1
fi

get_zone_id_success=$(echo "$get_zone_id_result" | awk -f JSON.awk "-" | grep '"success"')

for partial in $get_zone_id_success
do
  if [[ $partial != *.* && $partial != *,* ]] ; then
    if [[ $partial == "false" ]] ; then
      echo "Failed to list zones"
      echo ""
      echo "$get_zone_id_result"
      exit 1
    fi
  fi
done

if [ ! -z "$debug" ]; then
	echo "get_zone_id_result:"
	echo "$get_zone_id_result"
fi

echo "Printing zones listing result"
echo ""

echo "$get_zone_id_result" | awk -f JSON.awk "-" | grep '"result",0,"name"'
zone_id_with_field_name=$(echo "$get_zone_id_result" | awk -f JSON.awk "-" | grep '"result",0,"id"')
echo "$get_zone_id_result" | awk -f JSON.awk "-" | grep '"result",0,"id"'
echo "$get_zone_id_result" | awk -f JSON.awk "-" | grep '"result",0,"owner"'
echo "$get_zone_id_result" | awk -f JSON.awk "-" | grep '"result",0,"account"'
echo "$get_zone_id_result" | awk -f JSON.awk "-" | grep '"result",0,"name_servers"'

if [ ! -z "$debug" ]; then
  echo "zone_id_with_field_name"
  echo "$zone_id_with_field_name"
fi

for partial in $zone_id_with_field_name
do
  if [[ $partial != *.* && $partial != *,* ]] ; then
    partial="${partial%\"}"
    partial="${partial#\"}"
    zone_id="$partial"
  fi
done

echo ""
echo "Making request to list dns_records"
echo ""

get_dns_record_id_result=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records$optional_name_parameter_querystring" \
  -H "$auth_header" \
  -H "Content-Type: application/json")

if [ ! $? -eq 0 ]; then
	echo "Failed to list dns_records"
	echo "$get_dns_record_id_result"
	exit 1
fi

get_dns_record_id_success=$(echo "$get_dns_record_id_result" | awk -f JSON.awk "-" | grep '"success"')

for partial in $get_dns_record_id_success
do
  if [[ $partial != *.* && $partial != *,* ]] ; then
    if [[ $partial == "false" ]] ; then
      echo "Failed to list dns_records"
      echo ""
      echo "$get_dns_record_id_result"
      exit 1
    fi
  fi
done

if [ ! -z "$debug" ]; then
  echo "get_dns_record_id_result"
  echo "$get_dns_record_id_result"
fi

echo "Printing dns_record listing result"
echo ""

echo "$get_dns_record_id_result" | awk -f JSON.awk "-" | grep '"result",'

if [ -z "$host" ]; then
  echo ""
  echo "Set optional environment varialble \"HOST\" to reduce the number of return results, use \"*\" to represent root"
fi