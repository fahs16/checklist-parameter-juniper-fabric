#!/usr/bin/env bash
# =============================================================================
# run.sh - Auto run script via Docker biasa (tanpa docker compose).
#
# Script ini:
#   1. Cek image sudah ada / belum. Kalau belum, coba build (butuh internet).
#   2. Jalankan container dengan mount folder saat ini ke /app, jadi:
#        - command.txt & device_cred.txt dibaca dari host
#        - report.xlsx, report.csv, db.json, output-*.zip tersimpan di host
#
# Pemakaian:
#   ./run.sh
#
# Di server tanpa internet, pastikan image sudah di-load dulu:
#   docker load -i juniper-checklist.tar
# =============================================================================

set -euo pipefail

IMAGE="juniper-checklist:latest"

# Pindah ke folder tempat run.sh berada, apapun cwd saat dipanggil
cd "$(dirname "$0")"

# Pastikan file input ada
for f in command.txt device_cred.txt script.py; do
  if [[ ! -f "$f" ]]; then
    echo "❌ File '$f' tidak ditemukan di folder ini. Batal."
    exit 1
  fi
done

# Kalau image belum ada, coba build (hanya berhasil kalau ada internet)
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "ℹ️  Image '$IMAGE' belum ada, mencoba build (butuh internet)..."
  docker build -t "$IMAGE" .
fi

echo "🚀 Menjalankan container..."
docker run --rm \
  -v "$(pwd)":/app \
  -e TZ=Asia/Jakarta \
  "$IMAGE"

echo "✅ Selesai. Cek hasil di: report.xlsx, report.csv, dan output-*.zip"
