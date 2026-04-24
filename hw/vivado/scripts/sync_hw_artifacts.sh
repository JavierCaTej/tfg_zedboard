#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

PROJECT_NAME="${1:-tfg_zedboard}"
RUN_NAME="${2:-impl_1}"

RUN_DIR="${REPO_ROOT}/hw/vivado/${PROJECT_NAME}/${PROJECT_NAME}.runs/${RUN_NAME}"
ARTIFACTS_DIR="${REPO_ROOT}/artifacts/hw"
REPORTS_DIR="${ARTIFACTS_DIR}/reports"

if [[ ! -d "${RUN_DIR}" ]]; then
  echo "No existe la run de Vivado: ${RUN_DIR}" >&2
  exit 1
fi

mkdir -p "${ARTIFACTS_DIR}"
mkdir -p "${REPORTS_DIR}"

bit_count=0
rpt_count=0

shopt -s nullglob

for bit_file in "${RUN_DIR}"/*.bit; do
  cp -f "${bit_file}" "${ARTIFACTS_DIR}/"
  echo "Copiado BIT: $(basename "${bit_file}")"
  bit_count=$((bit_count + 1))
done

for rpt_file in "${RUN_DIR}"/*.rpt; do
  cp -f "${rpt_file}" "${REPORTS_DIR}/"
  echo "Copiado RPT: $(basename "${rpt_file}")"
  rpt_count=$((rpt_count + 1))
done

if [[ "${bit_count}" -eq 0 ]]; then
  echo "Aviso: no se encontró ningún .bit en ${RUN_DIR}" >&2
fi

if [[ "${rpt_count}" -eq 0 ]]; then
  echo "Aviso: no se encontró ningún .rpt en ${RUN_DIR}" >&2
fi

echo "Sincronización completada en ${ARTIFACTS_DIR}"
