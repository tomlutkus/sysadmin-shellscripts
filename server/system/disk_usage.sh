#!/usr/bin/env bash
#
# Script: disk_usage.sh
# Purpose: Small script to alert for disk usage exceeding thresholds
# 
# Copyright (C) 2026 Thomas Lutkus
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Compatibility: RHEL 9+, Ubuntu 20.04+
# Requires: user 
#
# Usage: ./script-name.sh [N] 
#        Where N is the percentage
#
# Author: Thomas Lutkus
# Date: 2025-01-19
# Version: 1.0

set -euo pipefail

# Script constants and variables go here

THRESHOLD="${1:-80}" && THRESHOLD="${THRESHOLD%\%}"
DISK_CMD="df -h --output=pcent,target | tail -n +2 | grep -Ev '/dev|/sys|/run|/boot|/snap|tmpfs'"

while read PCT MOUNT
do
	USAGE="${PCT%\%}"
	if [[ "${USAGE}" -gt "${THRESHOLD}" ]]
	then
		logger -t disk_usage.sh -p local0.warn "WARNING: ${MOUNT} at ${PCT}."
	fi
done < <(eval "${DISK_CMD}")

exit 0
