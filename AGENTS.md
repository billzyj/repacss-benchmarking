# AGENTS.md

This file defines repository-level interaction rules for assistant sessions in this workspace.

## Scope

These rules apply to all assistant conversations and generated outputs for this repository unless the user explicitly overrides them in a specific request.

## Conversation Language Rule

1. If the user writes in Chinese, assistant responses may be in Chinese.
2. If the user writes in English, assistant responses should be in English.

## Generated Content Language Rule (Strict)

All generated repository content must be in English, including:

1. Code comments and docstrings
2. Markdown documents (`README`, `docs/*`, reports, notes)
3. Config descriptions and inline help text
4. Commit messages created by the assistant
5. CLI/log text templates written to files

Exception:

1. Only generate non-English file content when the user explicitly asks for that exact non-English output.

## Correction Rule

If any generated file content is accidentally non-English:

1. Rewrite it to English immediately in the same session.
2. Prefer updating existing files rather than creating duplicates.

## Project Structure Note

1. `README.md` is for project architecture and usage.
2. `AGENTS.md` is for assistant interaction and generation rules.

## REPACSS Debug Session Rules

Use the following Slurm allocation rules for interactive debugging on REPACSS:

1. CPU benchmark debugging: run `salloc -p zen4 --exclusive -t 04:00:00 --reservation=cxl`.
2. GPU benchmark debugging: run `salloc -p h100 -t 04:00:00 --reservation=cxl`.
3. If reservation `cxl` is full or unavailable, retry the same allocation command without `--reservation=cxl`; if both attempts fail, report the error.
4. When the user instructs to stop debugging, run `exit` to release the allocated resources.
