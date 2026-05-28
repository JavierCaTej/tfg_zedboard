#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OVERLAY_BIN_DIR="${REPO_ROOT}/sw/buildroot/board/tfg_zedboard/rootfs-overlay/usr/local/bin"
TARGET_BIN="${SCRIPT_DIR}/tfg_axi_memtool"
CAMPAIGN_SCRIPT="${REPO_ROOT}/measurements/t11/run_rw_campaign.sh"

make -C "${SCRIPT_DIR}" tfg_axi_memtool

install -D -m 0755 "${TARGET_BIN}" "${OVERLAY_BIN_DIR}/tfg_axi_memtool"
install -D -m 0755 "${CAMPAIGN_SCRIPT}" "${OVERLAY_BIN_DIR}/run_rw_campaign.sh"

echo "Instalado ${OVERLAY_BIN_DIR}/tfg_axi_memtool"
echo "Instalado ${OVERLAY_BIN_DIR}/run_rw_campaign.sh"
