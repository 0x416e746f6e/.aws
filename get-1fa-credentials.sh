#!/bin/bash

set -e -o pipefail

pwd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $pwd/lib.sh

get_1fa_token
