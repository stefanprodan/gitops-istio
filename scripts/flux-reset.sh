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

helm -n flux delete flux
kubectl -n istio-system delete istiooperators.install.istio.io --all
helm -n flux delete helm-operator
helm -n istio-system delete flagger
helm -n istio-system delete flagger-grafana
kubectl delete ns istio-system
kubectl delete ns istio-operator
kubectl delete ns flux
