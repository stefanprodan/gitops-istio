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

ISTIO_VER="1.2.2"
REPO_ROOT=$(git rev-parse --show-toplevel)
TEMP=${REPO_ROOT}/temp
ISTIO_SYSTEM=${REPO_ROOT}/istio-system

mkdir -p ${ISTIO_SYSTEM}
mkdir -p ${TEMP}

helm repo add istio.io https://storage.googleapis.com/istio-release/releases/${ISTIO_VER}/charts

helm fetch --untar --untardir ${TEMP} istio.io/istio-init

rsync -avq --exclude='*certmanager*' ${TEMP}/istio-init/files/ ${ISTIO_SYSTEM}/

rm -rf ${REPO_ROOT}/temp
