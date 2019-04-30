#!/usr/bin/env bash

set -e

if [[ ! -x "$(command -v kubectl)" ]]; then
    echo "kubectl not found"
    exit 1
fi

if [[ ! -x "$(command -v helm)" ]]; then
    echo "helm not found"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)

helm delete --purge istio

kubectl delete -f ${REPO_ROOT}/istio-system/crd-10.yaml
kubectl delete -f ${REPO_ROOT}/istio-system/crd-11.yaml

kubectl delete ns istio-system


