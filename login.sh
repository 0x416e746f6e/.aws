#!/bin/bash

set -e -o pipefail

# Log the login attempt
TS=$( date +'%Y-%m-%dT%H:%M:%S%z' )
PID=$$
ARG=$( ps -ww -o args= -p $PID )
PARG=$( ps -ww -o args= -p $PPID )
PPPID=$( ps -o ppid= -p $PPID )
PPARG=$( ps -ww -o args= -p $PPPID )
PPPPID=$( ps -o ppid= -p $PPPID )
PPPARG=$( ps -ww -o args= -p $PPPPID )
printf '{ "ts": "%s", "grandgrandparent": { "pid": %s, "command": "%s" }, "grandparent": { "pid": %s, "command": "%s" }, "parent": { "pid": %s, "command": "%s" }, "self": { "pid": %s, "command": "%s" } }\n' \
    "${TS}" \
    "${PPPPID}" "${PPPARG}" \
    "${PPPID}" "${PPARG}" \
    "${PPID}" "${PARG}" \
    "${PID}" "${ARG}" \
  >> ${HOME}/.aws/login.log

if [[ -f ${HOME}/.aws/login.lock ]]; then
  if [[ -t 0 ]]; then
    >&2 echo "Warning: another login attempt might be ongoing in parallel!"
  else
    exit 1
  fi
fi

touch ${HOME}/.aws/login.lock

pwd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $pwd/lib.sh

save_2fa_token $( request_2fa_token )

rm -f ${HOME}/.aws/login.lock
