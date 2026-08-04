#!/bin/bash
# Source me to get all envs from environment and environment-runtime.env

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -a
source $SCRIPT_DIR/environment.env
source $SCRIPT_DIR/environment-runtime-container.env
set +a
