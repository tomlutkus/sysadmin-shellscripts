#!/usr/bin/env bash
#
# Script:      adduser.sh
# Description: Simple script to add batch users from file
# Author:      Thomas Lutkus
# Date:        2026-01-12
# Usage:       ./adduser.sh FILENAME
#
# Notes:       Requires an input file format username,password,secondary_group per line

set -euo pipefail

# Store input file as argument
FILENAME="${1}"


# Usage statement
usage () {
	echo "Usage: ${0} FILENAME" >&2
	exit 1
}

echo "Script to add batch users."

if [[ -z "${1}" ]]
then
	usage
fi

if [[ ! -e "${FILENAME}" ]]
then
	usage
fi


while IFS="," read -r USERNAME PASSWORD SECONDARY_GROUP
do
	# Test if blank line and skip it
	if [[ -z "${USERNAME}" ]] 
	then
		echo "Skipping blank line."
		continue
	fi
	
	# Check if group exists
	if ! getent group "${SECONDARY_GROUP}" &>/dev/null
	then
		echo "Group ${SECONDARY_GROUP} doesn't exist, creating it now."
		groupadd "${SECONDARY_GROUP}"
	fi

	# Add user with secondary group
	if ! getent passwd "${USERNAME}" &>/dev/null
	then
		echo "Creating user ${USERNAME} member of group ${SECONDARY_GROUP}."
		useradd -G "${SECONDARY_GROUP}" "${USERNAME}"
		# Capture if there was an error
		STATUS="${?}"
	else
		echo "User ${USERNAME} already exists! Skipping user creation." >&2
		continue
        fi

	if [[ "${STATUS}" -ne "0" ]]
	then
		echo "Error adding user ${USERNAME}." >&2
		exit 1
	fi
	
	# Set the password for the new user
	echo "${USERNAME}:${PASSWORD}" | chpasswd

done < "${FILENAME}"

echo "Script finished executing."

exit 0
