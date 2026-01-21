#!/usr/bin/env bash
#
# Script: log_rotate.sh
# Purpose: Simple log rotation scripts that takes directory name and days as arguments
# 
# Copyright (C) 2026 Thomas Lutkus
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Compatibility: distro-agnostic
# Requires: root 
#
# Usage: ./log_rotate.sh [DIRECTORY] [DAYS]
#
# Optional: echo "local0.* /var/log/log_rotate_script.log" | sudo tee /etc/rsyslog.d/log_rotate.conf
# And then: systemctl restart rsyslog
#
# Author: Thomas Lutkus
# Date: 2026-01-21
# Version: 1.1

set -euo pipefail

# Script constants and variables go here
LOG_DIR="${1:-/var/log}"
DAYS="${2:-7}"
ARCHIVE_DIR="${LOG_DIR}/archive"
TIMESTAMP=$(date +%Y%m%d)

# Check if running as super user
if [[ "${UID}" -ne 0 ]]
then
	logger -s -p local0.err "log_rotate.sh: This program requires root privileges."
	exit 1
fi

# Check if LOG_DIR exists to avoid find errors
if [[ ! -d "${LOG_DIR}" ]]
then
	logger -s -p local0.err "log_rotate.sh: ${LOG_DIR} is not a directory."
	exit 1
fi

# Store the files to be rotated to an array
mapfile -d '' FILES_TO_ROTATE < <(find "${LOG_DIR}" -maxdepth 1 -type f -name "*log*" -mtime +"${DAYS}" -print0)

# Execution
if [[ "${#FILES_TO_ROTATE[@]}" -gt 0 ]]
then
	# Creates the archive dir if it doesn't exist
	[[ -d "${ARCHIVE_DIR}" ]] || mkdir -p "${ARCHIVE_DIR}"
	
	# Compress the files in place
	gzip "${FILES_TO_ROTATE[@]}"

	# Move the new .gz files to the archive
	for FILE in "${FILES_TO_ROTATE[@]}"
	do
		# Get the file name without directory
		BASE_NAME=$(basename "${FILE}")

		# Move the compressed file to the archive with a time stamp
		mv "${FILE}.gz" "${ARCHIVE_DIR}/${BASE_NAME}_${TIMESTAMP}.gz"
	done

	# Create a log entry for the log rotation successful
	logger -t log_rotate.sh -p local0.info "Successfully rotated ${#FILES_TO_ROTATE[@]} logs to ${ARCHIVE_DIR}"
else
	# Create a log entry for no log files older than specified days
	logger -t log_rotate.sh -p local0.info "No logs found older than ${DAYS} days in ${LOG_DIR}. Nothing to do."
fi


# Future expansion: Clean archives older than 90 days

exit 0
