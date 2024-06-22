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

pwd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $pwd/lib.sh

set_lock

HELP_MESSAGE=<<EOF
        Login helper for aws mfa tool.

        Usage:

            ~/.aws/login.sh [options]

        Options:

            --custom-config <url_or_path>  Save custom config file from URL or path
            --help                         Show this help message
            --setup                        Run setup to save account and 2fa details

EOF


if [[ -z "$1" ]]; then
  echo "🚫 No argument provided."
  echo "${HELP_MESSAGE}"
  delete_lock
  exit 1
else
  case "$1" in
  --custom-config|-c)
      if [[ -z "$2" ]]; then
        echo "🚫 Usage: --custom-config <url_or_path>"
        delete_lock
        exit 1
      else
        save_custom_config "$2"
        delete_lock
        exit 0
      fi
      ;;
  --help|-h)
      echo "${HELP_MESSAGE}"
      delete_lock
      exit 0
      ;;
  --login|-l)
      save_2fa_token $( request_2fa_token )
      delete_lock
      exit 0
      ;;
  --setup|-s)
      save_setup
      delete_lock
      exit 0
      ;;
  *)
      echo "🚫 Argument not supported: $1"
      delete_lock
      exit 1
      ;;
  esac
fi
