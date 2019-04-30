#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel)

helm delete --purge istio

kubectl delete -f ${REPO_ROOT}/istio-system/

kubectl delete ns istio-system
kubectl delete ns prod


