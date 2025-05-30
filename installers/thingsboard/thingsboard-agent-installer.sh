#!/usr/bin/env bash

set -e
export DEBIAN_FRONTEND=noninteractive
PACKAGE_MANAGER=""

BASE_URL="https://raw.githubusercontent.com/amareensaleh/test-apt-respository/main"
BASE_INSTALLERS_URL="${BASE_URL}/installers"
#BASE_PACKAGES_URL="${BASE_URL}/packages"

#THINGSBOARD_AGENT_PACKAGE_URL=""
#THINGSBOARD_AGENT_PACKAGE_NAME=""

TMP_DIR="/tmp/dpz/flex"
#THINGSBOARD_TMP_DIR="$TMP_DIR/agents/thingsboard"

usage() {
  echo "Installer for thingsboard-agent packages (versions 1.0.0 and later)"
  echo "Usage: thingsboard-agent-installer.sh [OPTIONS]                      "
  echo "                                                              "
  echo "Valid OPTIONS are:                                            "
  echo " --thingsboard-agent-version <thingsboard_agent_version> (default: latest)  "
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --thingsboard-agent-version)
      shift
      THINGSBOARD_AGENT_VERSION=$1
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Invalid option $1"
      usage
      exit 1
  esac
  shift
done

## We only want to run as root
root_check() {
  if [[ $(whoami) != "root" ]]; then
    echo "This should only be run as root"
    exit 1
  fi
}

# resolve qbee agent version
resolve_thingsboard_agent_version() {
  if [[ -z $THINGSBOARD_AGENT_VERSION ]]; then
    echo "Thingsboard version not specified by user; attempting to fetch latest"
    THINGSBOARD_AGENT_VERSION=$(wget -O - -q "$BASE_URL/thingsboard/latest.txt")
    echo "Latest agent version is: $THINGSBOARD_AGENT_VERSION"
  fi
}

# construct the agent url
#resolve_thingsboard_agent_package_name() {
#  if [[ $PACKAGE_MANAGER == "dpkg" ]]; then
#    THINGSBOARD_AGENT_PACKAGE_NAME="thingsboard-agent_${THINGSBOARD_AGENT_VERSION}_${DEVICE_ARCHITECTURE}.deb"
#  elif [[ $PACKAGE_MANAGER == "rpm" ]]; then
#    THINGSBOARD_AGENT_PACKAGE_NAME="thingsboard-agent-${THINGSBOARD_AGENT_VERSION}-1.${DIST_TAG}.${DEVICE_ARCHITECTURE}.rpm"
#  fi
#}

#resolve_thingsboard_agent_package_url(){
#  if [[ $PACKAGE_MANAGER == "dpkg" ]]; then
#    THINGSBOARD_AGENT_PACKAGE_URL="${BASE_PACKAGES_URL}/dpkg/dists/stable/main/binary-${DEVICE_ARCHITECTURE}"
#  elif [[ $PACKAGE_MANAGER == "rpm" ]]; then
#    # todo: complete/validate PKG URL for rpm-based distros
#    THINGSBOARD_AGENT_PACKAGE_URL="${BASE_PACKAGES_URL}/rpm/${DIST_TAG}"
#  fi
#
#  echo "Package URL is ${THINGSBOARD_AGENT_PACKAGE_URL}"
#}

#resolve_thingsboard_agent_package(){
#  resolve_thingsboard_agent_version
#  resolve_thingsboard_agent_package_name
#  resolve_thingsboard_agent_package_url
#}

install_wget_tool () {
  local wget_installer
  wget_installer="wget_installer.sh"

  mkdir -p $TMP_DIR
  wget -q "${BASE_INSTALLERS_URL}/tools/" -O "${TMP_DIR}/${wget_installer}" || exit 1
  source "${TMP_DIR}/${wget_installer}"
  install_wget "$PACKAGE_MANAGER"
}

detect_package_manager() {
  if [[ -n $(command -v dpkg) ]]; then
    PACKAGE_MANAGER="dpkg"
  elif [[ -n $(command -v rpm) ]]; then
    PACKAGE_MANAGER="rpm"
  else
    echo "No supported package manager found, exiting."
    exit 1
  fi
}

detect_metadata(){
  local device_metadata
  device_metadata="device-metadata-utils.sh"
  mkdir -p $TMP_DIR
  wget -q "${BASE_INSTALLERS_URL}/tools/${device_metadata}" -O "${TMP_DIR}/${device_metadata}" || exit 1
  source "${TMP_DIR}/${device_metadata}"
  detect_device_architecture
  detect_os_distro
}

install_dpz_flex_list(){
  echo "Installing dpz-flex.list file"
  mkdir -p $TMP_DIR
  wget -q "${BASE_URL}/dpz-flex.list" -O "${TMP_DIR}/dpz-flex.list" || exit 1
  mv "${TMP_DIR}/dpz-flex.list" "/etc/apt/sources.list.d/dpz-flex.list"
}

install_thingsboard_agent(){
  echo "Installing thingsboard-agent version: ${THINGSBOARD_AGENT_VERSION}"
  if [[ $PACKAGE_MANAGER == "dpkg" ]]; then
    apt-get update
    apt-get install -y "thingsboard-agent=${THINGSBOARD_AGENT_VERSION}"
  elif [[ $PACKAGE_MANAGER == "rpm" ]]; then
    yum install -y "thingsboard-agent-${THINGSBOARD_AGENT_VERSION}"
  else
    echo "Unsupported package manager: $PACKAGE_MANAGER"
    return 1
  fi
}

#download_and_unpack_thingsboard_agent_package() {
#
#  local old_wd
#  old_wd=$(pwd)
#
#  echo "--- Downloading package to: ${download_dir}"
#  local download_dir
#  download_dir=$(mktemp -d "${THINGSBOARD_TMP_DIR}/thingsboard-agent-download.XXXXXXXX")
#  wget -q --show-progress -P "$download_dir" "${THINGSBOARD_AGENT_PACKAGE_URL}/${THINGSBOARD_AGENT_PACKAGE_NAME}" || exit 1
#  wget -q --show-progress -P "$download_dir" "${THINGSBOARD_AGENT_PACKAGE_URL}/SHA512SUMS" || exit 1
#  cd "$download_dir"
#
#  echo "--- Validating package checksum"
#  local  package_sha512sum
#  package_sha512sum=$(grep "${THINGSBOARD_AGENT_PACKAGE_NAME}$" SHA512SUMS)
#  if [[ -z "$package_sha512sum" ]]; then
#    echo "Error: Could not find SHA512 entry for ${THINGSBOARD_AGENT_PACKAGE_NAME}"
#    exit 1
#  fi
#  echo "$package_sha512sum" | sha512sum -c || exit 1
#
#  echo "Unpacking downloaded package: ${THINGSBOARD_AGENT_PACKAGE_NAME}"
#  local package_path
#  package_path="${download_dir}/${THINGSBOARD_AGENT_PACKAGE_NAME}"
#  echo "Package path: ${package_path}"
#  if [[ $PACKAGE_MANAGER == "dpkg" ]]; then
#    dpkg -i "${package_path}"
#  elif [[ $PACKAGE_MANAGER == "rpm" ]]; then
#    rpm -iU "${package_path}"
#  fi
#
#  echo "Cleaning up..."
#  rm -rf "${download_dir}"
#  cd "$old_wd"
#}

# restart the agent
#start_thingsboard_agent() {
#  if [ -f '/proc/1/comm' ]; then
#    init_comm=$(cat /proc/1/comm)
#    if [ "$init_comm" = "systemd" ]; then
#      systemctl --no-block restart thingsboard-agent
#    else
#      echo "Not running systemd, please start the agent manually."
#      echo " $ thingsboard-agent"
#    fi
#  fi
#}

root_check
detect_package_manager
detect_metadata
install_wget_tool
install_dpz_flex_list

resolve_thingsboard_agent_version
install_thingsboard_agent
