#!/usr/bin/env bash

set -o errexit

ISTIO_VER="1.1.4"
REPO_ROOT=$(git rev-parse --show-toplevel)
TEMP=${REPO_ROOT}/temp
ISTIO_SYSTEM=${REPO_ROOT}/istio-system

mkdir ${ISTIO_SYSTEM}
mkdir ${TEMP}

helm repo add istio.io https://storage.googleapis.com/istio-release/releases/${ISTIO_VER}/charts

helm fetch --untar --untardir ${TEMP} istio.io/istio-init

rsync -avq --exclude='*certmanager*' ${TEMP}/istio-init/files/ ${ISTIO_SYSTEM}/

rm -rf ${REPO_ROOT}/temp
