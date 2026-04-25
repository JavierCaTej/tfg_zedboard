#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LOG_DIR="${REPO_ROOT}/logs/vitis"
LOG_FILE="${LOG_DIR}/create_fsbl_$(date +%Y%m%d-%H%M%S).log"

mkdir -p "${LOG_DIR}"

cd "${REPO_ROOT}"

echo "Ejecutando XSCT para generar FSBL"
echo "Log: ${LOG_FILE}"

xsct sw/vitis/scripts/create_fsbl.tcl 2>&1 | tee "${LOG_FILE}"
