#!/bin/bash

echo "Running a script to install device identity"

DEVICE_NAME=""
DEVICE_CODE=""

IDENTITY_SERVICE_URL="https://flex.qa1.dominos.com/api/flex-device-service/deviceSetup/identity"
IDENTITY_PACKAGE_NAME="flex_device_identity.zip"

DEVICE_IDENTITY_CERTS_DIR="/etc/device-identity/dpz/flex"
DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR="/etc/device-trust/dpz/flex/agents/thingsboard"
TMP_DIR="/tmp/dpz/flex"

echo "Parsing input args"
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
  --output "${IDENTITY_PACKAGE_NAME}"
set +x  # disable debug tracing

if [[ $? -ne 0 ]] || [[ ! -s "$IDENTITY_PACKAGE_NAME" ]]; then
  echo "Failed to download identity package"
  exit 1
else
  echo "Successfully downloaded ${IDENTITY_PACKAGE_NAME}"
fi

OLD_WD=$(pwd)
mkdir -p "$DEVICE_IDENTITY_CERTS_DIR"
echo "Created dir: $DEVICE_IDENTITY_CERTS_DIR"

mkdir -p "$DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR"
echo "Created dir: $DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR"

TMP_UNZIP_DIR=$(mktemp -d "${TMP_DIR}/device-identity.XXXXXXXX") || exit 1
unzip -o ${IDENTITY_PACKAGE_NAME} -d $TMP_UNZIP_DIR || exit 1
cd "$TMP_UNZIP_DIR" || exit 1

mv deviceKey.pem "$DEVICE_IDENTITY_CERTS_DIR"
mv deviceCert.pem "$DEVICE_IDENTITY_CERTS_DIR"
echo "Device identity installed to $DEVICE_IDENTITY_CERTS_DIR"

mv thingsboardCA.pem "$DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR"
echo "Device trust installed to $DEVICE_TRUST_THINGSBOARD_CA_CERTS_DIR"

cd "$OLD_WD" || exit 1

echo "Cleaning up"
echo "Removing $IDENTITY_PACKAGE_NAME"
rm -rf "${IDENTITY_PACKAGE_NAME}"

echo "Removing $TMP_UNZIP_DIR"
rm -rf "${TMP_UNZIP_DIR}"