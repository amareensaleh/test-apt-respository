#!/bin/bash

echo "Running a script to install device identity"

DEVICE_NAME=""
DEVICE_CODE=""

IDENTITY_SERVICE_URL="https://flex.qa1.dominos.com/api/flex-device-service/deviceSetup/identity"

DEVICE_IDENTITY_CERTS_DIR="/etc/device-identity/dpz"
DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR="/etc/device-trust/dpz/agents/thingsboard"

echo "Parsing input args"
# Parse --key value style args
while [[ $# -gt 0 ]]; do
  case $1 in
    --deviceName)
      DEVICE_NAME="$2"
      shift 2
      ;;
    --deviceCode)
      DEVICE_CODE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$DEVICE_NAME" || -z "$DEVICE_CODE" ]]; then
  echo "Usage: $0 --deviceName <name> --deviceCode <code>"
  exit 1
fi

LOCATION="${IDENTITY_SERVICE_URL}"
echo "Requesting identity package for device: $DEVICE_NAME from: $LOCATION"

set -x  # enable debug tracing
curl -X POST --location  "${LOCATION}"\
  -H "Content-Type: application/json" \
  -d "{
        \"deviceName\": \"${DEVICE_NAME}\",
        \"deviceCode\": \"${DEVICE_CODE}\"
      }" \
  --output identity_package.zip
set +x  # disable debug tracing

if [[ $? -ne 0 || ! -f identity_package.zip ]]; then
  echo "Failed to download identity package"
  exit 1
fi

OLD_WD=$(pwd)
mkdir -p "$DEVICE_IDENTITY_CERTS_DIR"
mkdir -p "$DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR"

UNZIP_DIR=$(mktemp -d /tmp/dpz-device-identity.XXXXXXXX) || exit 1
unzip -o identity_package.zip -d $UNZIP_DIR || exit 1
cd "$UNZIP_DIR" || exit 1

mv deviceKey.pem "$DEVICE_IDENTITY_CERTS_DIR"
mv deviceCert.pem "$DEVICE_IDENTITY_CERTS_DIR"
echo "Device identity installed to $DEVICE_IDENTITY_CERTS_DIR"

mv thingsboardCA.pem "$DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR"
echo "Device trust installed to $DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR"

cd "$OLD_WD" || exit 1