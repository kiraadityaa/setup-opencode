---
description: Audit keamanan proyek (vuln, secret, config berisiko).
agent: build
---

Delegasikan audit keamanan ke subagent `security`:

- Pindai seluruh area kerja: kode, dependency manifest, konfigurasi, container, CI.
- Periksa secret yang bocor di git history (`git log -p` / `git grep`) jika beralasan.
- JANGAN memodifikasi file selama auditnya berjalan.
- Akhiri dengan laporan prioritas (kritis→minor) + rekomendasi perbaikan konkret.
- Tampilkan ringkasan eksekutif kepada pengguna.

Area / argumen: $ARGUMENTS