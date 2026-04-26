#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

IMAGES_DIR="${REPO_ROOT}/sw/buildroot/output/zedboard/images"
ARTIFACTS_DIR="${REPO_ROOT}/artifacts/buildroot"

if [[ ! -d "${IMAGES_DIR}" ]]; then
  echo "Error: no existe el directorio de imagenes de Buildroot: ${IMAGES_DIR}" >&2
  echo "Ejecuta primero: ./sw/buildroot/scripts/build_buildroot.sh" >&2
  exit 1
fi

mkdir -p "${ARTIFACTS_DIR}"

copy_required() {
  local source_file="$1"
  local target_file="$2"

  if [[ ! -e "${source_file}" ]]; then
    echo "Error: no existe el artefacto requerido: ${source_file}" >&2
    exit 1
  fi

  cp --sparse=always "${source_file}" "${target_file}"
}

copy_required "${IMAGES_DIR}/u-boot" "${ARTIFACTS_DIR}/u-boot.elf"
copy_required "${IMAGES_DIR}/uImage" "${ARTIFACTS_DIR}/uImage"
copy_required "${IMAGES_DIR}/system.dtb" "${ARTIFACTS_DIR}/system.dtb"
copy_required "${IMAGES_DIR}/zynq-zed.dtb" "${ARTIFACTS_DIR}/zynq-zed.dtb"
copy_required "${IMAGES_DIR}/rootfs.ext4" "${ARTIFACTS_DIR}/rootfs.ext4"
copy_required "${IMAGES_DIR}/rootfs.tar" "${ARTIFACTS_DIR}/rootfs.tar"
copy_required "${IMAGES_DIR}/sdcard.img" "${ARTIFACTS_DIR}/sdcard.img"
copy_required "${IMAGES_DIR}/extlinux.conf" "${ARTIFACTS_DIR}/extlinux.conf"

echo "Artefactos de Buildroot sincronizados en: ${ARTIFACTS_DIR}"
echo "Nota: boot.bin no se copia aqui; el BOOT.bin final se genera en T6 con FSBL, bitstream y u-boot.elf."
