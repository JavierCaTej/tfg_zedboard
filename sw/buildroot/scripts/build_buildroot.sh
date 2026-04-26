#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

BUILDROOT_VERSION="2023.02.9"
BUILDROOT_DIR="${REPO_ROOT}/sw/buildroot/buildroot-${BUILDROOT_VERSION}"
OUTPUT_DIR="${REPO_ROOT}/sw/buildroot/output/zedboard"
PROJECT_DEFCONFIG="${REPO_ROOT}/sw/buildroot/configs/tfg_zedboard_defconfig"

mkdir -p "${OUTPUT_DIR}"

if [[ "${1:-}" == "project-defconfig" ]]; then
  make -C "${BUILDROOT_DIR}" O="${OUTPUT_DIR}" defconfig BR2_DEFCONFIG="${PROJECT_DEFCONFIG}"
  exit 0
fi

make -C "${BUILDROOT_DIR}" O="${OUTPUT_DIR}" "$@"
