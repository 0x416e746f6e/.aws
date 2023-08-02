#!/bin/bash

set -e -o pipefail

pwd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $pwd/lib.sh

AWS_SESSION_TOKEN=$( get_2fa_token )
EXPIRATION=$( printf "${AWS_SESSION_TOKEN}" | jq -r ".Expiration" )
NOW=$( date -u +"%Y-%m-%dT%H:%M:%S%z" )

if [ "$NOW" \> "$EXPIRATION" ]; then
  $pwd/login.sh
  AWS_SESSION_TOKEN=$( get_2fa_token )
fi

printf "${AWS_SESSION_TOKEN}"
