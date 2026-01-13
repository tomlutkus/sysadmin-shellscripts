#!/usr/bin/env bash
#
# Script: user_access.sh
# Purpose: Create a user on the remote server and add pubkey
# 
# Copyright (C) 2026 Thomas Lutkus
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Compatibility: RHEL 9+, Ubuntu 20.04+
# Dependencies: ssh
# Requires: root
#
# Usage: ./user_acess.sh [options] [arguments]
#        ./script-name.sh --help
#
# Author: Thomas Lutkus
# Date: 2026-06-13
# Version: 1.0

set -euo pipefail

# Variables
SUDO="false"
DRY="false"
HASH_DIR="${HOME}/env/secrets/hashes"
PKEY_DIR="${HOME}/env/secrets/pubkeys"


# Functions
usage() {
	local EXIT_CODE="${1:-0}"
	local OUTPUT="${2:-1}"

	cat >&"${OUTPUT}" <<EOF
Usage: ${0} [OPTIONS] USERNAME
	-s		Defines that the user will have sudo privileges.
	-n		Dry run to see what the command will do.
	-h		Shows these usage instructions.
EOF

	exit "${EXIT_CODE}"
}

test_file() {
	if [[ ! -e "${1}" ]]
	then
		echo "There is no ${2} file for this user. Skipping user creation." >&2
		EXIT_CODE="2"
		return 1
	fi
	return 0
}


# Get Options
while getopts snh OPTION
do
	case ${OPTION} in
	s) SUDO="true" ;;
	n) DRY="true" ;;
	h) usage 0 1 ;;
	*) usage 1 2 ;;
	esac
done


# Shift to arguments
shift $(( OPTIND - 1 ))


# Tests before running the script
# Test that there are users specified
if [[ "${#}" -eq "0" ]]
then
	usage 1 2
fi


# Test that for superuser privileges
if [[ "${UID}" -ne "0" ]]
then
	echo "This script requires superuser privileges." >&2
	exit 1
fi


# Script logic
for USER in "${@}"
do
	HASH_FILE="${HASH_DIR}/${USER}.hash"
	PKEY_FILE="${PKEY_DIR}/${USER}.pub"
	
	# Test if the password hash for the user exists
	test_file "${HASH_FILE}" "hash" || continue

	# Test if the pukey file for the user exists
	test_file "${PKEY_FILE}" "pubkey" || continue

	# In Progress

done


# In Progress








