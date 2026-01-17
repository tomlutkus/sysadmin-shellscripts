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
# Compatibility: RHEL 8+, Ubuntu 20.04+, Arch Linux
# Dependencies: 
# Requires: root
#
# Usage: ./user_audit.sh
#
# Author: Thomas Lutkus
# Date: 2026-01-17
# Version: 1.0

set -euo pipefail

# Script constants and variables go here
EXIT_CODE="0"
mapfile -t SYS_USERS < <(awk -F: '$3 < 1000 && $3 != 0 {print $1}' /etc/passwd)
mapfile -t PPL_USERS < <(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd)

# Functions
# Test if the account has valid shell and unlocked password
test_sys() {
  local U="${1}"
  local U_SHELL=$(getent passwd "${U}" | cut -d: -f7)
  local U_PW=$(getent shadow "${U}" | cut -d: -f2)
  
  local VALID_SHELL=false
  local UNLOCKED_PW=false

  [[ "${U_SHELL}" != "/sbin/nologin" && \
   "${U_SHELL}" != "/usr/sbin/nologin" && \
   "${U_SHELL}" != "/usr/bin/nologin" && \
   "${U_SHELL}" != "/bin/false" ]] && VALID_SHELL=true
  [[ ! "${U_PW}" =~ ^[\!\*] && -n "${U_PW}" ]] && UNLOCKED_PW=true

  if "${VALID_SHELL}" && "${UNLOCKED_PW}"
  then
    echo "CRITICAL: System account ${U} - valid shell (${U_SHELL}) and unlocked password!"
  elif "${VALID_SHELL}"
  then
    echo "WARNING: System account ${U} - valid shell (${U_SHELL})."
  elif "${UNLOCKED_PW}"
  then
    echo "WARNING: System account ${U} - unlocked password."
  fi
}

test_ppl() {
  local U="${1}"
  local U_SHELL=$(getent passwd "${U}" | cut -d: -f7)
  local U_PW=$(getent shadow "${U}" | cut -d: -f2)
  local U_EXP=$(getent shadow "${U}" | cut -d: -f8) 
  local TODAY=$(( $(date +%s) / 86400 ))

  if [[ -f /etc/shells ]] && ! grep -qxF "${U_SHELL}" /etc/shells
  then
    echo "WARNING: The user account ${U} doesn't have a valid shell." >&2
  fi
  
  if [[ "${U_PW}" =~ ^[\!\*] ]]
  then
    echo "WARNING: The user account ${U} is locked!" >&2
  elif [[ -z "${U_PW}" ]]
  then
    echo "WARNING: The user account ${U} has no password!" >&2
  fi

  if [[ -n "${U_EXP}" && "${U_EXP}" -le "${TODAY}" ]]
  then
    echo "WARNING: The user account ${U} is expired!" >&2
  fi
}

if [[ "${UID}" -ne "0" ]]
then
  echo "This script requires super user privileges to run." >&2
  exit 1
fi

# Auditing system accounts
echo "Auditing system accounts..."

for U in "${SYS_USERS[@]}"
do
  # Test if the account has sudo privileges
  if sudo -l -U "${U}" 2>&1 | grep -q "may run"
  then
    echo "WARNING: System account ${U} has sudo privileges!" >&2
    EXIT_CODE="1"
  fi
  test_sys "${U}"
done

# Inform the user if system accounts were found to have sudo
if [[ "${EXIT_CODE}" -ne "0" ]]
then
  echo "All system accounts audited. The accounts listed above have sudo. You should investigate." >&2
else
  echo "All system accounts audited. No accounts were found to have sudo privileges."
fi

# Audit all the user accounts and print them to the screen
for U in "${PPL_USERS[@]}"
do
  # Check for sudo privileges and group membership
  U_GROUPS=$(id -nG "${U}")
  if sudo -l -U "${U}" 2>&1 | grep -q "may run"
  then
    echo "The user ${U} has sudo privileges and is a member of groups: ${U_GROUPS}."
  else
    echo "The user ${U} doesn't have any sudo privileges and is a member of groups: ${U_GROUPS}."
  fi

  # Check for account expiration, lock and lack of password
  test_ppl "${U}"

done
