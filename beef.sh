#!/usr/bin/env bash
# BeEF/beef.sh

# beef.sh
# 	Clone sites using BeEF


set -euo pipefail
# -e exit if any command returns non-zero status code
# -u prevent using undefined variables
# -o pipefail force pipelines to fail on first non-zero status code


# Define output messages
FATAL="\\033[1;31m[FATAL]\\033[0m"
# WARNING="\\033[1;33m[WARNING]\\033[0m"
PASS="\\033[1;32m[PASS]\\033[0m"
INFO="\\033[1;36m[INFO]\\033[0m"


function usage {

	# echo -e "\\nClone sites with BeEF\\n"
	echo -e "Usage: ./beef.sh [OPTIONS] -P {password} site_to_clone"

	echo -e "\\n 	-P	password: 	BeEF server password"
	echo "	-u 	username: 	BeEF server username 	(default: beef)"
	echo " 	-i 	beef_ip: 	BeEF server IP address	(default: 127.0.0.1)"
	echo "	-p 	beef_port: 	BeEF server port	(default: 3000)"
	echo "	-m 	mount_point: 	URL to mount page on 	(default: /)"
	echo -e "	-v 	Debug mode 	set -x\\n"


	exit 0
}


function get_api_token {

	echo -e "${INFO} Getting API token"

	# shellcheck disable=SC2086
	api_token=$(curl -s -H "Content-Type: application/json" \
				-d '{"username":"'${username}'", "password":"'${password}'"}' \
				-X POST "http://${beef_ip}:${beef_port}/api/admin/login" \
				| awk -F '"' '{print $6}')
				# HTTP hack

	if [ -z "${api_token}" ]; then

		echo -e "${FATAL} Failed to get API token"
		echo -e "${INFO} Check BeEF is running"
		echo -e "${INFO} Check BeEF username/password"
		echo -e "${INFO} Check BeEF ip and port are correct"
		exit 1
	else 
		echo -e "${PASS} Successfully got API token"
	fi
}


function clone_site {

	local api_result
	local api_status

	echo -e "${INFO} Attemping to clone http://${site_to_clone}"

	# shellcheck disable=SC2086
	api_result=$(curl -s -H "Content-Type: application/json; charset=UTF-8" \
				-d '{"url":"'http://${site_to_clone}'", "mount":"'${mount_point}'"}' \
				-X POST "http://${beef_ip}:${beef_port}/api/seng/clone_page?token=${api_token}")
				# HTTP hack

	api_status=$(echo "${api_result}" | \
				awk -F '"' '{print $2}')
	
	if [[ "${api_status}" == "success" ]]; then
		echo -e "${PASS} Successfully cloned http://${site_to_clone} to http://${beef_ip}:${beef_port}${mount_point}"
		# HTTP hack
		exit 0
	else
		echo -e "${FATAL} Failed to clone ${site_to_clone}"
		echo -e "${INFO} Is site_to_clone URL correct?"
		echo -e "${INFO} http(s):// should be omitted e.g -s hacksoc.co.uk"
		exit 1
	fi
}


function main {

	local cmd=${1:-""}
	api_token=""
	site_to_clone=""
	password=""
	debug="False"

	# Set some defaults
	username="beef"
	beef_ip="127.0.0.1"
	beef_port="3000"
	mount_point="/"

	while getopts hP:u:i:p:m:v option
	do
		case "${option}"
			in
			h)
				usage
				;;
			P) 
				password=${OPTARG}
				;;
			u) 
				username=${OPTARG}
				;;
			i) 
				beef_ip=${OPTARG}
				;;
			p) 
				beef_port=${OPTARG}
				;;
			m) 
				mount_point=${OPTARG}
				;;
			v)
				debug="debug"
				;;
			\?)
				usage
				;;
		esac
	done

	site_to_clone=${*:$OPTIND:1}

	if [ -z "${cmd}" ]; then
		usage
	elif [ -z "${password}" ]; then
		echo -e "${FATAL} password parameter required"
		usage
	elif [ -z "${site_to_clone}" ]; then
		echo -e "${FATAL} No site_to_clone specified"
		usage
	elif [[ "${debug}" == "debug" ]]; then
		set -x
	fi

	get_api_token
	clone_site
}


main "$@"