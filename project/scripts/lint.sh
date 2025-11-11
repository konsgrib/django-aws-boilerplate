#!/usr/bin/env bash

set -eux
cd $(dirname $0)/..

check=${1:-""}

echo `pwd`

black $check --target-version py311 --config ./scripts/black.toml ./