#!/bin/sh -l

VERSION=3.2.1
curl -sL https://get.helm.sh/helm-v${VERSION}-linux-amd64.tar.gz | tar xz

mkdir -p $GITHUB_WORKSPACE/bin
cp ./linux-amd64/helm $GITHUB_WORKSPACE/bin
rm -rf ./linux-amd64
chmod +x $GITHUB_WORKSPACE/bin/helm
ls -lh $GITHUB_WORKSPACE/bin

echo "::add-path::$GITHUB_WORKSPACE/bin"
echo "::add-path::$RUNNER_WORKSPACE/$(basename $GITHUB_REPOSITORY)/bin"
