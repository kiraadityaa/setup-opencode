---
description: Review kode (diff/PR) secara menyeluruh oleh subagent reviewer.
agent: build
---

Jalankan subagent `reviewer` untuk meninjau perubahan terbaru:

- Ambil scope: `git diff` terhadap staging/HEAD, atau `git diff <base>..HEAD` jika $ARGUMENTS berisi referensi (mis. nama branch/commit).
- Subagent lain tidak boleh mengedit; hanya menganalisis dan melaporkan.
- Laporkan temuan berdasarkan tingkat keparahan (critical/major/minor/nit) dengan referensi file:line.
- Setelah review selesai, tampilkan ringkasan 5 baris teratas dan tawarkan perbaikan otomatis yang aman.

Scope / argumen: $ARGUMENTS