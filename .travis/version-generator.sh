#!/bin/bash

generate_build_version_no() {
    if [[ ${TRAVIS_BRANCH} =~ \r\e\l\e\a\s\e\-\v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        export BUILD_VERSION="${TRAVIS_BRANCH:9}"
        export RELEASE=YES
    else
        export BUILD_VERSION="SNAPSHOT_${BUILD_TS}"
        export RELEASE=NO
    fi
}

generate_build_no() {
    export BUILD_REVISION=`git rev-parse HEAD`;
}

generate_build_date() {
    export BUILD_TS=`date +%Y%m%d_%H%M%S_%Z`
    export BUILD_DATE=`date "+%F %T %Z"`
}

generate_build_date
generate_build_version_no
generate_build_no

echo "BUILD_VERSION  : ${BUILD_VERSION}"
echo "BUILD_REVISION : ${BUILD_REVISION}"
echo "BUILD_DATE     : ${BUILD_DATE}"
echo "RELEASE        : ${RELEASE}"

unset -f generate_build_version_no
unset -f generate_build_no
unset -f generate_build_date
