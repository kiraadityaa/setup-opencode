# Compression payload rules

When writing summaries for the `compress` tool:

- Write plain Markdown: a single flowing paragraph (or a few short bullets), never a JSON blob, never a code snippet.
- Do NOT use double quotes `"` anywhere in the summary. Use single quotes `'` or rephrase instead.
- Do not paste raw values or commands verbatim if they contain quotes, backslashes, or newlines; paraphrase them.
- No trailing backslash or open code fence. Finish with a complete sentence.
- Keep it lean: only stable facts and decisions that must survive (paths, ids, commands, outcomes), no exploration noise.

These rules keep the toolcall payload JSON-safe so compression never fails with a parse error.