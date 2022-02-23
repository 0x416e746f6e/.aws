#!/bin/bash

set -e

_DEVICE="arn:aws:iam::176395444877:mfa/$( id -un )"

security find-generic-password -l "$_DEVICE" -a "$_DEVICE" -s "$_DEVICE" -w
