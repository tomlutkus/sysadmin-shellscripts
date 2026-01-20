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
# Author: Thomas Lutkus
# Date: 2026-01-20
# Version: 1.0

set -euo pipefail

# Script constants and variables go here
LOG_DIR="${1:-/var/log}"
DAYS="${2:-7}"
ARCHIVE_DIR="${LOG_DIR}/archive"
ROTATED_COUNT=$(find "${LOG_DIR}" -maxdepth 1 -name "*.log" -mtime +"${DAYS}" | wc -l)

# Creates the archive dir if it doesn't exist
[[ -d "${ARCHIVE_DIR}" ]] || mkdir -p "${ARCHIVE_DIR}"

# Script Logic
# Compress the files
find "${LOG_DIR}" -maxdepth 1 -name "*.log" -mtime +"${DAYS}" -exec gzip {} +

# Move the new .gz files to the archive
mv "${LOG_DIR}"/*.log.gz "${ARCHIVE_DIR}/" 2>/dev/null


# Log logic
# Optional: echo "local0.* /var/log/log_rotate_script.log" | sudo tee /etc/rsyslog.d/log_rotate.conf
# And then: systemctl restart rsyslog
# This is to direct the script to its own log file and keep things tidy
logger -t log_rotate.sh -p local0.info "Successfully rotated ${ROTATED_COUNT} logs to ${ARCHIVE_DIR}"

exit 0
