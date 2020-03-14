#!/usr/bin/env bash

set -e

if [[ ! -x "$(command -v kubectl)" ]]; then
    echo "kubectl not found"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)

curl -s https://istio.io/operator.yaml | grep -v '\.\.\.' > ${REPO_ROOT}/istio/operator.yaml

curl -s https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml > ${REPO_ROOT}/flagger/flagger-crds.yaml
