#!/bin/bash

set -e

_USER="arn:aws:iam::176395444877:user/$( id -un )"

security find-generic-password -l "$_USER" -a "$_USER" -s "$_USER" -w
