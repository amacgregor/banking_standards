# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Elixir library implementing banking and payment file standards. Only the NACHA ACH module (`lib/ach/`) is implemented; AFT, ISO 20022, and EDI 820 are listed in the README as planned but the directories don't exist yet — don't assume them when wiring new code.

## Commands

- `mix deps.get` — install dependencies
- `mix compile --warnings-as-errors` — CI runs this; warnings fail the build
- `mix format` / `mix format --check-formatted` — formatter is enforced in CI
- `mix test` — run tests
- `mix test path/to/file_test.exs:LINE` — run a single test
- `mix credo --strict` — style/lint (once added)
- `mix dialyzer` — static analysis (`dialyxir` is already in deps)
- `mix ex_dna` — AST-based duplication detector (once added)

The full pre-commit gate is bundled into the `/verify` skill.

## Quality tooling (planned additions to `mix.exs`)

These need to be added before they can run. The `/verify` skill will skip any tool that isn't installed yet.

- `credo` — style linter
- `ex_slop` — Credo plugin catching AI-generated Elixir slop (blanket rescues, narrator docs, N+1 queries, etc.). Configured in `.credo.exs` via `plugins: [{ExSlop, []}]` — it runs as part of `mix credo`, not as its own task.
- `ex_dna` — AST duplication detector. Mix task: `mix ex_dna`.
- `dialyxir` — already present; run with `mix dialyzer`.

## Pre-commit expectations

CI rejects PRs that fail any of these. Run `/verify` before commit:

1. `mix format --check-formatted`
2. `mix compile --warnings-as-errors`
3. `mix test`
4. `mix credo --strict`
5. `mix ex_dna`
6. `mix dialyzer`

## Workflow

- Feature branches, PR to `main`.
- Version is derived from `git describe` in `mix.exs` — shallow clones (some CI configs) will fail `app_version/0`. If you hit this, fetch tags rather than hardcoding a version.

## ACH module structure

`lib/ach/` follows a record-type-per-module pattern: `parser.ex` orchestrates; `batch_headers.ex`, `entry_details.ex`, `file_control.ex` each own one NACHA record type. When adding a new record type, mirror that pattern — see `/add-ach-record` skill.
