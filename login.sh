#!/bin/bash

set -e

_DEVICE="arn:aws:iam::176395444877:mfa/$( id -un )"

printf "Enter one-time password for \`$_DEVICE\`: "; read _PIN

_TOKEN=$( aws --profile 1fa sts get-session-token --serial-number $_DEVICE --token-code $_PIN | jq -r -c ".Credentials + { \"Version\": 1 }" )

security delete-generic-password -l "$_DEVICE" -a "$_DEVICE" -s "$_DEVICE" > /dev/null 2>&1 || true

security add-generic-password -l "$_DEVICE" -a "$_DEVICE" -s "$_DEVICE" -w "$_TOKEN"
