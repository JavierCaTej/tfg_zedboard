#!/bin/sh

set -eu

OUT_ROOT="/root/t11/raw"
BUILD_ID=""
REPS=""
ITERS=""
WARMUP=""
TOOL="tfg_axi_memtool"

usage() {
  echo "Uso: $0 --id ID --reps N --iters N --warmup N [--out DIR]"
  echo
  echo "Ejemplo:"
  echo "  $0 --id t11-rw-100M-warmup-1M-5rep --reps 5 --iters 100000000 --warmup 1000000"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --id)
      BUILD_ID="$2"
      shift 2
      ;;
    --reps)
      REPS="$2"
      shift 2
      ;;
    --iters)
      ITERS="$2"
      shift 2
      ;;
    --warmup)
      WARMUP="$2"
      shift 2
      ;;
    --out)
      OUT_ROOT="$2"
      shift 2
      ;;
    --tool)
      TOOL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Opcion no reconocida: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$BUILD_ID" ] || [ -z "$REPS" ] || [ -z "$ITERS" ] || [ -z "$WARMUP" ]; then
  usage >&2
  exit 1
fi

DATE_TAG="$(date +%Y%m%d_%H%M%S)"
CAMPAIGN_DIR="${OUT_ROOT}/${DATE_TAG}_${BUILD_ID}"
LOG_FILE="${CAMPAIGN_DIR}/campaign_log.txt"
CONFIG_FILE="${CAMPAIGN_DIR}/campaign_config.txt"

mkdir -p "$CAMPAIGN_DIR"

{
  echo "build_id=$BUILD_ID"
  echo "date=$DATE_TAG"
  echo "bitstream=tfg_zedboard_bd_wrapper.bit"
  echo "xsa=tfg_zedboard.xsa"
  echo "dtb=system.dtb"
  echo "buildroot_release=2023.02.9"
  echo "fclk=100MHz"
  echo "repetitions=$REPS"
  echo "iters=$ITERS"
  echo "warmup=$WARMUP"
  echo "tool=$TOOL"
  echo "out_dir=$CAMPAIGN_DIR"
  echo "command=$TOOL rw-loop --iters $ITERS --warmup $WARMUP --build-id $BUILD_ID -C $CAMPAIGN_DIR"
} > "$CONFIG_FILE"

echo "Campaign: $BUILD_ID" | tee "$LOG_FILE"
echo "Carpeta: $CAMPAIGN_DIR" | tee -a "$LOG_FILE"

# Validacion minima antes de empezar una Campaign larga.
ID_VALUE="$($TOOL read 0x00)"
if [ "$ID_VALUE" != "0x54464700" ]; then
  echo "REG_ID no es el esperado: $ID_VALUE" | tee -a "$LOG_FILE" >&2
  exit 1
fi

i=1
while [ "$i" -le "$REPS" ]; do
  RUN_NAME="$(printf 'run_%03d' "$i")"
  TMP_OUT="${CAMPAIGN_DIR}/.${RUN_NAME}.out"
  TMP_ERR="${CAMPAIGN_DIR}/.${RUN_NAME}.err"

  echo "Lanzando $RUN_NAME de $REPS" | tee -a "$LOG_FILE"

  if ! "$TOOL" rw-loop \
      --iters "$ITERS" \
      --warmup "$WARMUP" \
      --build-id "$BUILD_ID" \
      -C "$CAMPAIGN_DIR" > "$TMP_OUT" 2> "$TMP_ERR"; then
    echo "Fallo en $RUN_NAME" | tee -a "$LOG_FILE" >&2
    cat "$TMP_OUT" >> "$LOG_FILE"
    cat "$TMP_ERR" >> "$LOG_FILE"
    exit 1
  fi

  cat "$TMP_OUT" >> "$LOG_FILE"
  cat "$TMP_ERR" >> "$LOG_FILE"

  CSV_FILE="$(sed -n 's/^csv_file=//p' "$TMP_ERR" | tail -n 1)"
  if [ -z "$CSV_FILE" ] || [ ! -f "$CSV_FILE" ]; then
    echo "No encuentro el CSV generado en $RUN_NAME" | tee -a "$LOG_FILE" >&2
    exit 1
  fi

  mv "$CSV_FILE" "${CAMPAIGN_DIR}/${RUN_NAME}.csv"
  rm -f "$TMP_OUT" "$TMP_ERR"

  i=$((i + 1))
done

echo "Campaign terminada correctamente" | tee -a "$LOG_FILE"
echo "Resultados en: $CAMPAIGN_DIR"
