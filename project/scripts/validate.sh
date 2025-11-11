#!/usr/bin/env bash

set -eux
cd $(dirname $0)/..
. ./scripts/includes.sh
setup $@

aws cloudformation validate-template \
    --template-body file://${template_path}

if command -v cfn-lint &> /dev/null; then
    cfn-lint -t ${template_path} --ignore-checks W,E3001,E3002,E3003,E0000 --regions ${aws_region}
else
    echo "cfn-lint not installed, skipping lint check"
fi