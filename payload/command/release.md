---
description: Siapkan rilis: bump versi, update changelog, beri tag.
agent: build
---

Siapkan rilis dalam langkah-langkah, JANGAN push/tag otomatis tanpa konfirmasi:

1. Tentukan versi baru (major.minor.patch) berdasarkan $ARGUMENTS atau perubahan sejak tag terakhir (`git tag --sort=-version:refname | head` dan `git log`).
2. Update nomor versi sesuai konvensi proyek (package.json, pyproject.toml, Cargo.toml...).
3. Perbarui CHANGELOG (Tambahkan/Diubah/Diperbaiki) berdasarkan commit sejak rilis terakhir.
4. Stage perubahan dan siapkan pesan commit `chore(release): vX.Y.Z`.
5. Saat sudah disetujui, buat tag `vX.Y.Z` (`git tag -a vX.Y.Z`) — tetap TANYA dulu sebelum push.

Catatan / argumen: $ARGUMENTS