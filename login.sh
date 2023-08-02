#!/bin/bash

set -e -o pipefail

pwd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. $pwd/lib.sh

save_2fa_token $( request_2fa_token )
