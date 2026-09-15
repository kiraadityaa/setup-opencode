---
description: Tulis dan jalankan tes untuk proyek.
agent: build
---

Tentukan framework tes yang dipakai (lihat package.json, pyproject.toml, go.mod, dll.), lalu delegasikan pembuatan/eksekusi tes ke subagent `test-writer`:

- Pahami struktur proyek dan cari direktori tes yang ada.
- Tulis tes untuk perubahan terbaru / area sesuai $ARGUMENTS.
- Jalankan suite terkait dan pastikan lolos.
- Laporkan coverage singkat dan perbaikan jika ada yang gagal.

Area / argumen: $ARGUMENTS