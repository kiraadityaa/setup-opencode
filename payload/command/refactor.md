---
description: Refactor kode dengan aman, bertahap, dan terverifikasi.
agent: build
---

Refactor dengan prinsip perubahan kecil yang aman:

1. Identifikasi area dari $ARGUMENTS dan jelaskan rencana refactor singkat (iapa yang berubah, kenapa).
2. Jalankan tes yang ada HANYA sebelum mulai (`git status`, lalu suite tes terkait) untuk baseline.
3. Lakukan refactor bertahap — satu langkah logis per perubahan. Jaga perilaku tetap sama.
4. Setiap selesai satu langkah, jalankan kembali tes/lint terkait.
5. Jangan gabungkan perubahan yang tidak berhubungan; dorong commit terpisah sesuai konvensi.
6. Laporkan diff summary di akhir.

Area / argumen: $ARGUMENTS