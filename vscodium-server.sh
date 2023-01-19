#!/usr/bin/env bash
# Script to launch VSCodium Remote Execution Host
# Including:
# - downloading releases only when needed
# - managing cached versions
# - launching server with predetermined config
#
# Inspired by: https://github.com/xaberus/vscode-remote-oss
#
# (C) 2023 metalwanderer / https://github.com/metalwanderer
set -e

VSCODIUM_DIR="${HOME}/lib/vscodium-server"
VSCODIUM_VERSION=""
PACKAGE="vscodium-reh-linux-x64-${VSCODIUM_VERSION}.tar.gz"
PACKAGE_URL="https://github.com/VSCodium/vscodium/releases/download/${VSCODIUM_VERSION}/${PACKAGE}"
KEEP_PKGS=3
CONNECTION_TOKEN=""
SOCKET_PATH="${VSCODIUM_DIR}/socket"

# shopt must be set globally or bash will fail to parse update_cache()
shopt -s extglob nullglob

# Check if current package version is in cache, and download only if needed
update_cache () {
    if [ ! -f "${CACHE_DIR}/${PACKAGE}" ] ; then
        mkdir -p "${CACHE_DIR}"
        pushd "${CACHE_DIR}" >/dev/null
        wget "${PACKAGE_URL}"
        [ -n "$(echo !(${PACKAGE}))" ] && rm !("${PACKAGE}")
        popd >/dev/null
    fi
}

# Unpack the latest package and update current symlink as needed
update_commit () {
    if [ ! -d "${BIN_DIR}" ]; then
        mkdir -p "${BIN_DIR}"
        pushd "${BIN_DIR}" >/dev/null
        tar -xf "${CACHE_DIR}/${PACKAGE}"
        popd >/dev/null
        pushd "${VSCODIUM_DIR}/bin" >/dev/null
        ln -sfn "${COMMIT}" "current"
        popd >/dev/null
    fi
}

# Cleanup cached packages and server instances
clean_cache () {
    local pkg commit
    for pkg in $(
        find "${CACHE_DIR}/" -maxdepth 1 -type f -printf "%T@ %p\n" | \
        sort -nr | \
        awk '{print $2}' | \
        tail -n +${KEEP_PKGS} | \
	grep -v "${VSCODIUM_VERSION}"
    ) ; do
        rm -f "${pkg}"
    done
    for commit in $(
        find "${VSCODIUM_DIR}/bin/" -mindepth 1 -maxdepth 1 -type d -printf "%T@ %p\n" | \
        sort -nr | \
        awk '{print $2}' | \
        tail -n +${KEEP_PKGS} | \
	grep -v "${COMMIT}"
    ) ; do
        rm -rf "${commit}"
    done
}

# Launch the server and begin listening
start_server () {
  ${VSCODIUM_DIR}/bin/current/bin/codium-server \
      --socket-path "${SOCKET_PATH}" \
      --telemetry-level off \
      --connection-token "${CONNECTION_TOKEN}"
  
  rm -f "${SOCKET_PATH}"
}

# Create directory st ructure
mkdir -p "${VSCODIUM_DIR}"
pushd "${VSCODIUM_DIR}" >/dev/null

# Download packages
CACHE_DIR="${VSCODIUM_DIR}/cache"
update_cache

# Extract package and update commit reference
COMMIT=$(tar -xf "${CACHE_DIR}/${PACKAGE}" ./product.json -O | jq ".commit" -r)
BIN_DIR="${VSCODIUM_DIR}/bin/${COMMIT}"
update_commit

# Clean up old versions
clean_cache

# Launch server
start_server

popd >/dev/null
exit 0
