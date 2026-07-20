# =============================================================================
# Dockerfile untuk checklist-parameter-juniper-fabric
# -----------------------------------------------------------------------------
# Tujuan  : Membungkus script.py beserta seluruh Python module (paramiko,
#           pandas, openpyxl) ke dalam image, supaya bisa dijalankan di server
#           yang TIDAK punya akses internet.
#
# Alur    : Build image di mesin yang PUNYA internet  ->  simpan jadi .tar
#           (docker save)  ->  pindahkan ke server  ->  docker load  ->  run.
#
# Catatan : script.py memakai f-string nested-quote (PEP 701), jadi WAJIB
#           Python 3.12 ke atas.
# =============================================================================

FROM python:3.12-slim

# Zona waktu (opsional) - bikin timestamp output sesuai WIB
ENV TZ=Asia/Jakarta \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Install Python module SAAT BUILD (butuh internet di tahap ini saja).
# Setelah image jadi, module sudah tertanam di dalam image.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Salin script ke dalam image. File input (command.txt, device_cred.txt)
# dan file output (db.json, report.xlsx, dst) di-mount saat runtime lewat
# volume, jadi TIDAK di-copy ke dalam image.
COPY script.py .

# Jalankan script secara default
CMD ["python", "script.py"]
