#!/usr/bin/env bash

DEVICE_ARCHITECTURE=""
DIST_TAG=""

detect_os_distro(){
  echo "Attempting to detect device OS distro"
  if [[ $PACKAGE_MANAGER == "rpm" ]]; then
    . /etc/os-release # Read OS-release info
    case "$ID" in
      rhel|centos|rocky|almalinux|ol)
        DIST_TAG="el${VERSION_ID%%.*}"
        ;;
      fedora)
        DIST_TAG="fc${VERSION_ID%%.*}"
        ;;
      amzn)
        if [[ "$VERSION_ID" == "2" ]]; then
          DIST_TAG="el7"
        else
          DIST_TAG="generic"
        fi
        ;;
      opensuse*)
        DIST_TAG="suse"
        ;;
      *)
        DIST_TAG="generic"
        ;;
    esac
  fi
  echo "Device OS distro is: ${DIST_TAG}"
}

detect_device_architecture() {
  echo "Attempting to detect device architecture"
  if [[ $PACKAGE_MANAGER == "dpkg" ]]; then
    DEVICE_ARCHITECTURE=$(dpkg --print-architecture)
  elif [[ $PACKAGE_MANAGER == "rpm" ]]; then
    DEVICE_ARCHITECTURE=$(rpm --eval '%{_arch}')
  fi
  echo "Device architecture is: ${DEVICE_ARCHITECTURE}"
}