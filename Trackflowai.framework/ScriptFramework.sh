##!/bin/sh
#
##  ScriptFramework.sh
##  Trackflow
##
##  Created by Anooj Krishnan G on 03/10/20.
##  Copyright © 2020 Synclovis Systems Pvt Ltd. All rights reserved.
#
#if [ “true” == ${ALREADYINVOKED:-false} ]
#
#then
#
#echo “RECURSION: Detected, stopping”
#
#else
#
#export ALREADYINVOKED=“true”
#
#UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-iosuniversal
#
## make sure the output directory exists
#
#mkdir -p “${UNIVERSAL_OUTPUTFOLDER}”
#
## Step 1. Build Device and Simulator versions
#
#xcodebuild -target “${TARGET_NAME}” ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphoneosBUILD_DIR=“${BUILD_DIR}” BUILD_ROOT=“${BUILD_ROOT}” clean build
#
#xcodebuild -target “${TARGET_NAME}” -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR=“${BUILD_DIR}” BUILD_ROOT=“${BUILD_ROOT}” clean build
#
## Step 2. Copy the framework structure (from iphoneos build) to the universal folder
#
#cp -R “${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework” “${UNIVERSAL_OUTPUTFOLDER}/”
#
## Step 3. Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
#
#SIMULATOR_SWIFT_MODULES_DIR=“${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule/.”
#
#if [ -d “${SIMULATOR_SWIFT_MODULES_DIR}” ]; then
#
#cp -R “${SIMULATOR_SWIFT_MODULES_DIR}” “${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/Modules/${PROJECT_NAME}.swiftmodule”
#
#fi
#
## Step 4. Create universal binary file using lipo and place the combined executable in the copied framework directory
#
#lipo -create -output “${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/${PROJECT_NAME}” “${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}” “${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}”
#
#fi

#--------------------------------------------------------------------------
code_sign() {
# Use the current code_sign_identitiy
echo "Code Signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME}"
echo "/usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} --preserve-metadata=identifier,entitlements $1"
/usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} --preserve-metadata=identifier,entitlements "$1"
}

echo "Stripping frameworks"
cd "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

for file in $(find . -type f -perm +111); do
# Skip non-dynamic libraries
if ! [[ "$(file "$file")" == *"dynamically linked shared library"* ]]; then
continue
fi
# Get architectures for current file
archs="$(lipo -info "${file}" | rev | cut -d ':' -f1 | rev)"
stripped=""
for arch in $archs; do
if ! [[ "${VALID_ARCHS}" == *"$arch"* ]]; then
# Strip non-valid architectures in-place
lipo -remove "$arch" -output "$file" "$file" || exit 1
stripped="$stripped $arch"
fi
done
if [[ "$stripped" != "" ]]; then
echo "Stripped $file of architectures:$stripped"
if [ "${CODE_SIGNING_REQUIRED}" == "YES" ]; then
code_sign "${file}"
fi
fi
done

#--------------------------------------------------------------------------------------
#lipo -create 'device/Trackflow.framework/Trackflow' 'simulator/Trackflow.framework/Trackflow' -output Trackflow.framework/Trackflow
