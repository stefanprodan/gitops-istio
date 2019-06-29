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
REPO_URL=${1:-git@github.com:stefanprodan/gitops-istio}
REPO_BRANCH=master
TEMP=${REPO_ROOT}/temp

rm -rf ${TEMP} && mkdir ${TEMP}

cat <<EOF >> ${TEMP}/flux-values.yaml
helmOperator:
  create: true
  createCRD: true
  configureRepositories:
    enable: true
    volumeName: repositories-yaml
    secretName: flux-helm-repositories
    cacheVolumeName: repositories-cache
    repositories:
      - caFile: ""
        cache: stable-index.yaml
        certFile: ""
        keyFile: ""
        name: stable
        password: ""
        url: https://kubernetes-charts.storage.googleapis.com
        username: ""
      - caFile: ""
        cache: istio.io-index.yaml
        certFile: ""
        keyFile: ""
        name: istio.io
        password: ""
        url: https://storage.googleapis.com/istio-release/releases/1.2.2/charts
        username: ""
      - caFile: ""
        cache: flagger-index.yaml
        certFile: ""
        keyFile: ""
        name: flagger
        password: ""
        url: https://flagger.app
        username: ""
EOF

helm repo add weaveworks https://weaveworks.github.io/flux

echo ">>> Installing Flux for ${REPO_URL}"
helm upgrade -i flux --wait \
--set git.url=${REPO_URL} \
--set git.branch=${REPO_BRANCH} \
--set git.pollInterval=1m \
--set registry.pollInterval=1m \
--namespace flux \
-f ${TEMP}/flux-values.yaml \
weaveworks/flux

kubectl -n flux rollout status deployment/flux

echo '>>> GitHub deploy key'
kubectl -n flux logs deployment/flux | grep identity.pub | cut -d '"' -f2