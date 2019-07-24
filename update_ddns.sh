#!/bin/bash

# This script is used to check and update your CloudFlare DNS server to the IP address of your current internet connection.
# First go to Cloudflare personal profile page API Token tab
#
# https://www.cloudflare.com
#
# Create new API Token, DO NOT USE API Key
# The only permission this script need is the permission to edit DNS in your designated Zone which is "Zone.DNS"/"example.com DNS:Edit"
# 
# Update the variables with your information
 
zone_id="$ZONE_ID"		# go to your dashboard for the zone, it should appear in your address bar
dns_record_id="$DNS_RECORD_ID"		# change your dns record in dashboard and capture the request in browser dev console
api_token="$API_TOKEN"		# cloudflare api token, do not include "Bearer"
ip_detector_endpoint="$IP_DETECTOR_ENDPOINT"		# any public ip echo service endpoint that returns JSON or IP in a string
ttl="$TTL"		# ttl for the record, 1 for auto
debug="true"

if [[ "${DEBUG,,}" == "false" || "${DEBUG,,}" == "no" ]]; then
	debug=""
fi

cloudflare_json_response_hostname_field_key="name"		# the json field name holding the hostname in cloudflare response

cloudflare_json_response_hostname_field_key_cut_length=$((${#cloudflare_json_response_hostname_field_key}+4))		# adding double quotes and colon into account

cloudflare_hostname_match_regex='"'"$cloudflare_json_response_hostname_field_key"'":"\b([a-zA-Z0-9]{1,}\.){1,}[a-zA-Z0-9]{0,}\b'

ip_match_regex='\b([0-9]{1,3}\.){3}[0-9]{1,3}\b'

if [ ! -z "$ttl" ]; then
	ttl="1"
fi

if [ ! -z "$debug" ]; then
	echo "Hostname matching regex:"
	echo "$cloudflare_hostname_match_regex"
fi

auth_header="Authorization: Bearer $api_token"

if [ ! -z "$debug" ]; then
	echo "Authorization header:"
	echo "$auth_header"
fi

exist_dns_record_response=$(curl -s -X GET -H "$auth_header" -H "Content-Type: application/json" \
 "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$dns_record_id")

if [ ! $? -eq 0 ]; then
	echo "Failed to retrieve DNS record"
	echo "$exist_dns_record_response"
	exit 1
fi

if [ ! -z "$debug" ]; then
	echo "Exist DNS record response:"
	echo "$exist_dns_record_response"
fi

exist_dns_ip=$(echo $exist_dns_record_response | grep -oE $ip_match_regex)
exist_dns_record_name=$(echo $exist_dns_record_response | grep -oE $cloudflare_hostname_match_regex)
exist_dns_record_name=${exist_dns_record_name:cloudflare_json_response_hostname_field_key_cut_length}

if [ -z "$exist_dns_ip" ]; then
	echo "Cannot parse existing DNS record IP"
	exit 1
fi

if [ -z "$exist_dns_record_name" ]; then
	echo "Cannot parse existing DNS record hostname"
	exit 1
fi

ip_detector_endpoint_response=$(curl -s GET "$ip_detector_endpoint")
detected_ip=$(echo $ip_detector_endpoint_response | grep -oE $ip_match_regex)

if [ -z "$detected_ip" ]; then
	echo "Cannot parse detected IP"
	exit 1
fi

echo "Found exist DNS record for hostname: $exist_dns_record_name , Zone: $zone_id , DNS record: $dns_record_id, detected IP: $detected_ip, existing DNS record IP: $exist_dns_ip"

if [ "$detected_ip" != "$exist_dns_ip" ]; then
	echo "Updating DNS record for hostname: $exist_dns_record_name , Zone: $zone_id , DNS record: $dns_record_id with IP: $detected_ip"
	update_dns_record_request_data='{"type":"A","name":"'"$exist_dns_record_name"'","content":"'"$detected_ip"'","ttl":'"$ttl"',"proxied":false}'
	if [ ! -z "$debug" ]; then
		echo "Update request payload data:"
		echo $update_dns_record_request_data
	fi
	update_dns_record_result=$(curl -i -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$dns_record_id" \
		-H "$auth_header" \
		-H "Content-Type: application/json" \
		-d $update_dns_record_request_data)

	if [ $? -eq 0 ]; then
		echo "Successfully updated DNS record"
	else
		echo "Failed to update DNS record"
		echo "You may set DEBUG to true for debugging"
		echo "Update response:"
		echo $update_dns_record_result
	fi

	if [ ! -z "$debug" ]; then
		echo "Update response:"
		echo $update_dns_record_result
	fi
else
	echo "No need to update"
fi
