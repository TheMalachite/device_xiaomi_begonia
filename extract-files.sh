#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=begonia
VENDOR=xiaomi

INITIAL_COPYRIGHT_YEAR=2019

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

POTATO_ROOT="${MY_DIR}"/../../..

HELPER="${POTATO_ROOT}/vendor/potato/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    vendor/etc/init/init.wlan_drv.rc)
        sed -i "s/insmod/#insmod/g" ${2}
        ;;
    vendor/bin/hw/android.hardware.wifi@1.0-service-lazy-mediatek)
        patchelf --replace-needed libwifi-hal.so libwifi-hal-mtk.so ${2}
        patchelf --add-needed libcompiler_rt.so ${2}
        ;;
    vendor/bin/hw/hostapd)
        patchelf --add-needed libcompiler_rt.so ${2}
        ;;
    vendor/bin/hw/wpa_supplicant)
        patchelf --add-needed libcompiler_rt.so ${2}
        ;;
    vendor/lib/hw/audio.primary.mt6785.so)
        patchelf --replace-needed libmedia_helper.so libmedia_helper-v29.so ${2}
        ;;
    vendor/lib64/hw/audio.primary.mt6785.so)
        patchelf --replace-needed libmedia_helper.so libmedia_helper-v29.so ${2}
        ;;
    esac
}

# Initialize the helper for common device
setup_vendor "${DEVICE}" "${VENDOR}" "${POTATO_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
