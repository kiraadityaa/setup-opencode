---
description: Commit perubahan dengan pesan conventional commit.
agent: build
---

Review status dan diff dulu:

1. Jalankan `git status --short` dan `git diff --stat`, lalu `git diff` untuk perubahan yang akan di-commit.
2. Hanya stage file yang relevan dengan perubahan ini (jangan paksa `git add .`).
3. Buat pesan commit format Conventional Commits:
   `type(scope): subject` — type: feat|fix|docs|style|refactor|perf|test|build|ci|chore.
   Subject: imperative, singkat (<72 karakter). Tambahkan body jika ada alasan penting.
4. Jangan pernah menyertakan kredensial, token, atau path absolut pada pesan.
5. Commit dengan `git commit -m "..."` saja — JANGAN push kecuali diminta.

Argumen tambahan (opsional): $ARGUMENTS