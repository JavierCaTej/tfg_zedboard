#!/bin/sh

set -e

BOARD_DIR="$(dirname "$0")"
REPO_ROOT="$(cd "${BOARD_DIR}/../../../.." && pwd)"
BITSTREAM="${REPO_ROOT}/artifacts/hw/tfg_zedboard_bd_wrapper.bit"

if [ ! -f "${BITSTREAM}" ]; then
    echo "Error: no existe el bitstream esperado: ${BITSTREAM}" >&2
    exit 1
fi

# U-Boot busca por defecto system.dtb en la particion boot.
FIRST_DT=$(sed -n \
           's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="\([a-z0-9\-]*\).*"$/\1/p' \
           "${BR2_CONFIG}")

[ -z "${FIRST_DT}" ] || ln -fs "${FIRST_DT}.dtb" "${BINARIES_DIR}/system.dtb"

cp "${BITSTREAM}" "${BINARIES_DIR}/tfg_zedboard_bd_wrapper.bit"

support/scripts/genimage.sh -c "${BOARD_DIR}/genimage.cfg"
