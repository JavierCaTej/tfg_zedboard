#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
BOOT_DIR="${REPO_ROOT}/artifacts/boot"
LOG_DIR="${REPO_ROOT}/logs/vitis"

FSBL_ELF="${BOOT_DIR}/fsbl.elf"
BIT_FILE="${REPO_ROOT}/artifacts/hw/tfg_zedboard_bd_wrapper.bit"
UBOOT_ELF="${REPO_ROOT}/artifacts/buildroot/u-boot.elf"
BIF_FILE="${BOOT_DIR}/tfg_zedboard_boot.bif"
BOOT_BIN="${BOOT_DIR}/BOOT.bin"
LOG_FILE="${LOG_DIR}/generate_boot_bin_$(date +%Y%m%d-%H%M%S).log"

mkdir -p "${BOOT_DIR}"
mkdir -p "${LOG_DIR}"

if ! command -v bootgen >/dev/null 2>&1; then
    echo "Error: bootgen no esta disponible en PATH" >&2
    exit 1
fi

for required_file in "${FSBL_ELF}" "${BIT_FILE}" "${UBOOT_ELF}"; do
    if [[ ! -f "${required_file}" ]]; then
        echo "Error: falta el fichero requerido ${required_file}" >&2
        exit 1
    fi
done

cat > "${BIF_FILE}" <<EOF
the_ROM_image:
{
    [bootloader]${FSBL_ELF}
    ${BIT_FILE}
    ${UBOOT_ELF}
}
EOF

echo "Generando BOOT.bin con bootgen"
echo "BIF: ${BIF_FILE}"
echo "Log: ${LOG_FILE}"

bootgen -arch zynq -image "${BIF_FILE}" -o "${BOOT_BIN}" -w on 2>&1 | tee "${LOG_FILE}"

echo "BOOT.bin generado en: ${BOOT_BIN}"
