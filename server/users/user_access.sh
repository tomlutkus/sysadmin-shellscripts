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
EXIT_CODE="0"

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

error_handling() {
	local CMD_CODE="${1}"			# Capture the status of last command
	local MSG="${2}"					# Message about the step which was taking place
	if [[ "${CMD_CODE}" -ne 0 ]]
	then
		echo "${MSG} has failed. Skipping." >&2
		EXIT_CODE="3"
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
for NEW_USER in "${@}"
do
	HASH_FILE="${HASH_DIR}/${NEW_USER}.hash"
	PKEY_FILE="${PKEY_DIR}/${NEW_USER}.pub"
	
	# Test if the password hash for the user exists
	test_file "${HASH_FILE}" "hash" || continue

	# Test if the pukey file for the user exists
	test_file "${PKEY_FILE}" "pubkey" || continue

	# Creates account if user doesn't exist already
	if getent passwd "${NEW_USER}" &>/dev/null
	then
		echo "User ${NEW_USER} is found. Moving to next step."
	else
		TASK="Creating user ${NEW_USER}"
		echo "${TASK}."
		useradd -m -d /home/"${NEW_USER}" -s /bin/bash -c "Added by script ${0}" "${NEW_USER}"
		error_handling "${?}" "${TASK}" || continue
	fi
	
	# Sets a user password in accordance with the hash file
	TASK="Setting the password for ${NEW_USER}"
	echo "${TASK}."
	echo "${NEW_USER}:$(cat ${HASH_FILE})" | chpasswd &>/dev/null
  error_handling "${?}" "${TASK}"

	# User receives sudo privilege if option was chosen
	if [[ "${SUDO}" == "true" ]]
	then
		TASK="Adding user ${NEW_USER} to group wheel"
		echo "${TASK}."
		usermod -aG wheel "${NEW_USER}"
		error_handling "${?}" "${TASK}"
	fi

	# Create the .ssh folder for the user
	TASK="Creating the .ssh folder for the user ${NEW_USER}"
	echo "${TASK}."
	SSH_DIR="/home/${NEW_USER}/.ssh"
	mkdir -p "${SSH_DIR}" && 	chmod 700 "${SSH_DIR}" 
	error_handling "${?}" "${TASK}"

	# Create the authorized_keys file
	TASK="Creating the .ssh/authorized_keys file for the user ${NEW_USER}"
	echo "${TASK}."
	AUTH_FILE="/home/${NEW_USER}/.ssh/authorized_keys"
	cp "${PKEY_FILE}" "${AUTH_FILE}" && chmod 600 "${AUTH_FILE}"
	error_handling "${?}" "${TASK}"

	# Change the ownership of .ssh to the user
	chown -R "${NEW_USER}": "${SSH_DIR}"

	echo "Finished processing user ${NEW_USER}."
	echo

done


if [[ "${EXIT_CODE}" -ne "0" ]]
then
	echo "The script has finished running. There were errors, please check the log." >&2
	exit 1
else
	echo "The script has finished running. No errors."
	exit 0
fi
