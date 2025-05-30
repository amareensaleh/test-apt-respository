#!/usr/bin/env bash

install_wget () {
  local package_manager="$1"
  local wget_cmd
  wget_cmd=$(command -v wget || true)

  if [[ -n $wget_cmd ]]; then
    echo "wget already exists...skipping"
    return
  fi

  if [[ $package_manager == "dpkg" ]]; then
    apt-get update
    apt-get install -y wget
  elif [[ $package_manager == "rpm" ]]; then
    yum install -y wget
  else
    echo "Unsupported package manager: $package_manager"
    return 1
  fi
}