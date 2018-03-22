#!/usr/bin/env bash
# BeEF/install.sh

# install.sh
#	Install BeEF
#	Based on: https://github.com/beefproject/beef/wiki/Installation
# Tested on:
#	Kali:
#		2018.1
#	Debian:
#		9 (stretch) 


set -eo pipefail
# -e exit if any command returns non-zero status code
# -o pipefail force pipelines to fail on first non-zero status code
# Cannot use -u, it causes 'source ${HOME}/.rvm/scripts/rvm' to fail
# 	Error: ${HOME}/.rvm/scripts/functions/support/: line 182: _system_name: unound variable


FATAL="\\033[1;31mFATAL\\033[0m"
WARNING="\\033[1;33mWARNING\\033[0m"
PASS="\\033[1;32mPASS\\033[0m"
INFO="\\033[1;36mINFO\\033[0m"


function check_compatibility {

	# Check if Distribution is Kali or Debian
	# If Kali check if version is 2018.1 
	# If Debian check if version 9 (stretch)
	# Set target_os to Kali or Debian

	local kali_supported_version
	local debian_supported_version
	local distribution_id
	local os_version_id

	target_os=""
	kali_supported_version="2018.1"
	debian_supported_version="9"
	distribution_id="$(lsb_release -i | awk '{print $3}')"
	os_version_id="$(grep "VERSION_ID" /etc/os-release | awk -F '"' '{print $2}')"

	echo -e "[${INFO}] Checking OS compatability"

	if [[ "${distribution_id}" == "Kali" ]]; then

		echo -e "[${INFO}] Checking Kali version compatability"
		
		if [[ ! "${os_version_id}" == "${kali_supported_version}" ]]; then
			echo -e "[${WARNING}] Only tested on Kali Rolling ${kali_supported_version}"
			target_os="Kali"
			sleep 2
		else
			echo -e "[${PASS}] Sucessfully completed compatability check"
			target_os="Kali"
		fi
	
	elif [[ "${distribution_id}" == "Debian" ]]; then 

		echo -e "[${INFO}] Checking Debian version compatability"

		if [[ ! "${os_version_id}" == "${debian_supported_version}" ]]; then
			echo -e "[${WARNING}] Only tested on Debian ${debian_supported_version}"
			target_os="Debian"
			sleep 2
		else
			echo -e "[${PASS}] Sucessfully completed compatability check"
			target_os="Debian"
		fi
		
	else

		echo -e "[${FATAL}] Only tested on Kali/ Debian"
		exit 1
	fi
}


function install_dependencies {

	# Install curl, git and nodejs via apt
	# Install python3 and python3-pip via apt
	
	local deps=(curl git nodejs python3 python3-pip \
		build-essential openssl libreadline6-dev zlib1g \
		zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 \
		libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev \
		autoconf libc6-dev libncurses5-dev automake libtool \
		bison)

	echo -e "[${INFO}] Installing dependencies via apt-get" 

	# apt update runs even if all deps are present 
	sudo apt-get -qq update
	
	for package in "${deps[@]}"; do
		if sudo apt-get -qq install -y "${package}"; then
			echo -e "[${PASS}] ${package} installed"
		else
			echo -e "[${FATAL}] Failed to install ${package} install"
			exit 1
		fi
	done

	# Clean up any redundant dependencies
	sudo apt-get -qq autoremove -y
}


function check_ruby_version_manager {

	ruby_version_manager=" "
	# rvm or rbenv
	local ruby_version_manager_choice=" "
	# Boolean y/n
	local install_rvm_bool="n"
	# Boolean y/n

	if ! [ -x "$(command -v rvm)" ] && ! [ -x "$(command -v rbenv)" ]; then
		# Check if RVM or rbenv are present
		echo -e "[${WARNING}] No Ruby version manager installed"
		echo -e "[${WARNING}] Using a version manager like RVM or rbenv is highly recommended"
		echo -e "[${INFO}] If you'd like to manually install rbenv see: \
		\\n       https://github.com/rbenv/rbenv#installation \
		\\n       https://gist.github.com/0xmachos/3cb7d989facbe8dc568b8d4912846a81"
		echo -e "[${INFO}] This script can automtically install RVM"

		# If no version manager ask user if they want to install RVM
		echo -en "[${INFO}] Do you want to install RVM? (y/N) "
		read -r  install_rvm_bool

		# Loop untill the user answers one of n/N/y/Y
		while ! [[ "${install_rvm_bool}" =~ ^(n|N|y|Y)$ ]];
		do
			echo -en "[${INFO}] Do you want to install RVM? (y/N) "
			unset install_rvm_bool

			read -r  install_rvm_bool
		done

		if [[ "${install_rvm_bool}" =~ ^(y|Y)$ ]]; then
			# If the user answers yes then call install_rvm
			echo -e "[${PASS}] User has chosen to install RVM"
			install_rvm_bool="y"

			install_rvm
		else

			echo -e "[${FATAL}] User has chosen not to install RVM"
			echo -e "[${FATAL}] Install RVM or rbenv then rerun this script"
			exit 1
		fi
	
	elif [ -x "$(command -v rvm)" ] && [ -x "$(command -v rbenv)" ]; then
		# Check if both RVM and rbenv are present
		echo -e "[${WARNING}] Mutiple Ruby version managers installed: RVM and rbenv"
		echo -e "[${INFO}] This script prefers RVM over rbenv"

		# If both installed ask the user if they want to continue with RVM
		# This script prefers RVM to rbenv 
		echo -en "[${INFO}] Do you want to continue using RVM or rbenv? (rvm/rbenv) "
		read -r  ruby_version_manager_choice

		# Loop untill the user answers one of rvm/RVM/rbenv/RBENV
		while ! [[ "${ruby_version_manager_choice}" =~ ^(rvm|RVM|rbenv|RBENV)$ ]];
		do

			echo -en "[${INFO}] Do you want to continue using RVM or rbenv? (rvm/rbenv) "
			unset ruby_version_manager_choice

			read -r  ruby_version_manager_choice
		done

		if [[ "${ruby_version_manager_choice}" =~ ^(rvm|RVM)$ ]]; then
			# If users answers RVM/rvm then set ruby_version_manager to rvm
			# ruby_version_manager is queried in main 
			ruby_version_manager="rvm"

			echo -e "[${PASS}] User has chosen to continue using RVM"
		elif [[ "${ruby_version_manager_choice}" =~ ^(rbenv|RBENV)$ ]]; then
			
			ruby_version_manager="rbenv"

			echo -e "[${PASS}] User has chosen to continue using rbenv"			
		fi

	elif [ -x "$(command -v rvm)" ]; then
		# Check if RVM is installed and set ruby_version_manager
		# ruby_version_manager is queried in main 
		ruby_version_manager="rvm"

		echo -e "[${PASS}] ${ruby_version_manager} already installed"

	elif [ -x "$(command -v rbenv)" ]; then
		# Check if rbenv is installed and set ruby_version_manager
		# ruby_version_manager is queried in main 
		ruby_version_manager="rbenv"

		echo -e "[${PASS}] ${ruby_version_manager} already installed"

	else 
		# Totally fucked it
		echo -e "[${FATAL}] Unknown error"
		exit 1
	fi
}


function source_rvm {

	if [[ "${target_os}" == "Kali" ]]; then 
		# shellcheck disable=SC1091
		source "/etc/profile.d/rvm.sh"

	elif [[ "${target_os}" == "Debian" ]]; then
		# shellcheck disable=SC1090
		source "${HOME}/.rvm/scripts/rvm"

	else 
		echo -e "[${FATAL}] Compatibility issue"
		exit 1
	fi
}


function install_rvm {

	# Fetch RVM PGP signing key, add it to keyring
	# Install RVM via https://get.rvm.io

	if ! [ -x "$(command -v rvm)" ]; then

		echo -e "[${INFO}] Installing RVM, this will take a while..."
		if gpg --list-keys | grep -q "409B6B1796C275462A1703113804BB82D39DC0E3" ; then
			echo -e "[${INFO}] RVM signing key already in keyring"
		else

			echo -e "[${INFO}] Getting RVM signing key"
			if curl -sSL https://rvm.io/mpapis.asc | gpg --import - ; then
				echo -e "[${PASS}] Sucessfully imported RVM signing key"
			else
				echo -e "[${FATAL}] Failed to get or import RVM signing key"
				exit 1
			fi
		fi

		echo -e "[${INFO}] Getting and installing RVM"
		if curl -sSL https://get.rvm.io | bash -s stable ; then
			echo -e "[${PASS}] Installed RVM"
			source_rvm
		else

			echo -e "[${FATAL}] Failed to install RVM"
			exit 1
		fi

	else
		echo -e "[${PASS}] RVM already installed"
	fi
}


function rvm_install_ruby {

	# Install Ruby ${ruby_version} via RVM
	# Set Ruby ${ruby_version} as default for RVM 

	source_rvm

	if rvm list default | grep -q "${ruby_version}" ; then
		echo -e "[${PASS}] RVM default Ruby version already ${ruby_version}"
	else
		echo -e "[${INFO}] Installing Ruby ${ruby_version}"
		if rvm install "${ruby_version}" ; then
			echo -e "[${PASS}] Ruby ${ruby_version} installed"
    		if rvm use "${ruby_version}" -- default ; then
    			echo -e "[${PASS}] Set ${ruby_version} as RVM default"
    		else
    			echo -e "[${FATAL}] Failed to set ${ruby_version} as RVM default"
    		fi
    	else
    		echo -e "[${FATAL}] Failed to install Ruby ${ruby_version}"
    		exit 1
    	fi
    fi
}


function rbenv_install_ruby {

	# Install Ruby ${ruby_version} via rbenv

	if rbenv install -l | grep -q "${ruby_version}" ; then
		echo -e "[${PASS}] rbenv Ruby version already ${ruby_version}"
	else
		echo -e "[${INFO}] Installing Ruby ${ruby_version} via rbenv"
		if rbenv install "${ruby_version}" ; then
			echo -e "[${PASS}] Ruby ${ruby_version} installed via rbenv"
    	else
    		echo -e "[${FATAL}] Failed to install Ruby ${ruby_version} via rbenv"
    		exit 1
    	fi
    fi
}


function get_beef {

	# Check for existing 'beef' directory
	# Rename existing 'beef' directory
	# Clone github.com/beefproject/beef into 'beef'

	local move_time
	local old_beef_dir_name
	move_time=$(date +%b%d-%H:%M-%Z)
	old_beef_dir_name="beef.old.${move_time}"

	if [ -d "beef" ]; then
		echo -e "[${INFO}] Renaming existing 'beef' directory to '${old_beef_dir_name}'"
		mv -f "beef" "${old_beef_dir_name}"
	fi

	echo -e "[${INFO}] Cloning BeEF source"
	if git clone "git://github.com/beefproject/beef.git" ; then
		echo -e "[${PASS}] Sucessfully cloned BeEF source into 'beef'"
	else
		echo -e "[${FATAL}] Failed clone BeEF source"
		exit 1
	fi
}


function install_beef {

	# Change directory to 'beef'
	# Source '/etc/profile.d/rvm.sh' again just to be sure
	# Install Bundler via gem
	# Install BeEF via bundle[r]

	cd beef || exit

	source_rvm

	echo -e "[${INFO}] Installing Bundler"
	if gem install bundler ; then
		echo -e "[${PASS}] Sucessfully installed bundler"
		exit 0
	else
		echo -e "[${FATAL}] Failed to install bundler"
		exit 1
	fi

	if bundle install --without test development ; then
		echo -e "[${PASS}] Sucessfully installed BeEF"
		exit 0
	else
		echo -e "[${FATAL}] Failed to install BeEF"
		exit 1
	fi
}


function main {

	ruby_version="2.3.0"

	check_compatibility
	install_dependencies
	check_ruby_version_manager

	if [[ "${ruby_version_manager}" == "rvm" ]] ; then
		rvm_install_ruby
	elif [[ "${ruby_version_manager}" == "rbenv" ]]; then
		rbenv_install_ruby
	fi

	get_beef
	install_beef
}


main "$@"