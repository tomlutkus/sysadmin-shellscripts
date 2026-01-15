#!/usr/bin/env bash
#
# Script: user_audit.sh
# Purpose: Script to audit all the users on a system and their privilege level
# 
# Copyright (C) 2026 Thomas Lutkus
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Compatibility: RHEL 9+, Ubuntu 20.04+
# Dependencies: 
# Requires: root
#
# Usage: ./user_audit.sh [options] [arguments]
#        ./script-name.sh --help
#
# Author: Thomas Lutkus
# Date: 2026-01-17
# Version: 1.0

set -euo pipefail

# Script constants and variables go here
