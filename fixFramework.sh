#!/bin/bash
set -e
FLEX_SDK_PATH=~/.gradle/gradleFx/sdks/$(ls ~/.gradle/gradleFx/sdks/ | head -1)
cd ${FLEX_SDK_PATH}/frameworks/libs/
ln -s osmf.swc OSMF.swc