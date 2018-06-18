#!/bin/bash

generate-version-no() {
    if [ "${TRAVIS_TAG}" == "" ]; then
        export VERSION="SNAPSHOT-`git rev-parse --abbrev-ref HEAD`"
    else
        export VERSION="${TRAVIS_TAG:1}"
    fi

    if [ "${VERSION}" == "HEAD" ]; then
        export VERSION="SNAPSHOT-`git rev-parse --abbrev-ref HEAD`"
    fi
}

generate-build-no() {
    export BUILD=`git rev-parse HEAD`;
}

generate-version-no
generate-build-no

echo "VERSION : ${VERSION}"
echo "BUILD   : ${BUILD}"

unset -f generate-version-no
unset -f generate-build-no