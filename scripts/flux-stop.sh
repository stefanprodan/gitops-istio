#!/usr/bin/env bash

set -e

if [[ ! -x "$(command -v kubectl)" ]]; then
    echo "kubectl not found"
    exit 1
fi

kubectl -n flux scale deployment flux --replicas=0
kubectl -n flux scale deployment helm-operator --replicas=0
