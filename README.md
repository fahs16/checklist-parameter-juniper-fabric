# checklist-parameter-juniper-fabric
Automation generate some output from SSH Juniper to XLSX  
only if all required commands is inserted  
this is just a raw script as template or sample case if I want to create another function  
basically it is SSH automation using paramiko that support multiple command and it is connected via jumphost or bastion  
if you use this script, make sure remove db.json, report.csv, and report.xlsx before running the script   
this script is automatically update the report.xlsx based on db.json within the timestamp when you run  

---

# Menjalankan via Docker (server tanpa internet)

Server produksi tidak punya akses internet, jadi kita tidak bisa `pip install`
langsung di sana. Solusinya: **module Python (paramiko, pandas, openpyxl) kita
tanam ke dalam Docker image** di mesin yang punya internet, lalu image-nya kita
pindahkan ke server dalam bentuk file `.tar`.

Script ini memakai f-string nested-quote (PEP 701), jadi image memakai
**Python 3.12**. Semua sudah diatur di `Dockerfile`.

File yang ditambahkan:
- `Dockerfile` — resep image (Python 3.12 + module).
- `requirements.txt` — daftar module: paramiko, pandas, openpyxl.
- `docker-compose.yml` — mempermudah run + mount folder.
- `.dockerignore` — supaya file output tidak ikut masuk image.

## Langkah 1 — Build image (di mesin yang PUNYA internet)

```bash
# di dalam folder project
docker build -t juniper-checklist:latest .
```

Tahap build inilah satu-satunya tahap yang butuh internet (untuk `pip install`).
Setelah image jadi, semua module sudah tertanam di dalamnya.

## Langkah 2 — Simpan image jadi file .tar

```bash
docker save -o juniper-checklist.tar juniper-checklist:latest
```

## Langkah 3 — Pindahkan & load di server (TANPA internet)

Salin `juniper-checklist.tar` ke server (scp / USB / dsb), lalu:

```bash
docker load -i juniper-checklist.tar
```

Cek image sudah masuk:

```bash
docker images | grep juniper-checklist
```

## Langkah 4 — Siapkan file input di server

Di folder kerja, siapkan:
- `command.txt`      — daftar command Juniper (satu per baris).
- `device_cred.txt`  — daftar device, format: `ip|||user|||password`.
- `script.py`        — sudah ada di dalam image, tapi kalau di-mount folder,
  versi di host yang dipakai (lihat cara run di bawah).

Jangan lupa: **hapus dulu `db.json`, `report.csv`, `report.xlsx`** kalau ingin
report bersih dari awal.

Sebelum juga **edit variabel jumphost** di `script.py` (baris 11-13):
```python
jumphost_ip   = "10.175.1.151"
jumphost_user = "USER"
jumphost_pass = "PASSWORD"
```

## Langkah 5 — Jalankan (exec)

### Opsi A — pakai docker compose (paling gampang)

```bash
docker compose run --rm checklist
```

Folder project otomatis di-mount ke `/app`, jadi `command.txt` &
`device_cred.txt` dibaca dari host, dan `report.xlsx` langsung muncul di host.

### Opsi B — pakai docker run biasa

```bash
docker run --rm \
  -v "$(pwd)":/app \
  juniper-checklist:latest
```

`-v "$(pwd)":/app` = mount folder saat ini ke dalam container. Ini penting
supaya:
- input (`command.txt`, `device_cred.txt`) terbaca, dan
- output (`db.json`, `report.csv`, `report.xlsx`, `output-<timestamp>/`)
  tersimpan langsung ke folder host, bukan hilang di dalam container.

### Masuk ke dalam container (debug / manual)

```bash
docker run --rm -it -v "$(pwd)":/app juniper-checklist:latest bash
# lalu di dalam:
python script.py
```

## Langkah 6 — Ambil file .xlsx hasilnya

Karena folder host di-mount ke container, file hasil **langsung ada di folder
kerja host** setelah run selesai:

```bash
ls -l report.xlsx report.csv
```

`report.xlsx` inilah laporan akhir (dengan formatting & highlight perubahan).
Tinggal `scp` ke laptop untuk dibuka di Excel:

```bash
scp user@server:/path/ke/project/report.xlsx .
```

> Catatan: `report.xlsx` hanya digenerate kalau **semua 11 parameter checklist**
> terpenuhi (semua command wajib ada di `command.txt`). Kalau belum lengkap,
> hanya file per-parameter di `output-<timestamp>/` yang terisi.
