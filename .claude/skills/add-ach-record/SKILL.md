---
name: add-ach-record
description: Reference for adding a new NACHA ACH record type to lib/ach/, following the existing parser/batch_headers/entry_details/file_control pattern.
---

Use this when the user asks to add a new ACH record type (e.g., addenda records, IAT records) or extend an existing one.

## Existing pattern in `lib/ach/`

- `parser.ex` — orchestrates parsing across record types; dispatch lives here.
- `batch_headers.ex`, `entry_details.ex`, `file_control.ex` — one module per NACHA record type. Each owns its own field layout, parsing, and validation.
- Tests for each record type live alongside in `test/ach/`.

## Steps for a new record type

1. Read `lib/ach/parser.ex` and one existing record module (e.g., `lib/ach/batch_headers.ex`) to confirm the current shape before generating new code — these modules are the source of truth, not this skill.
2. Create `lib/ach/<record_name>.ex` mirroring the chosen reference module's structure: field definitions, parse function, validation.
3. Wire dispatch into `parser.ex` — find where the existing record types are matched and add the new one.
4. Add `test/ach/<record_name>_test.exs` with a parse test, a validation test, and at least one malformed-input test.
5. Run `/verify` before reporting done.

## NACHA reference

Each NACHA record is a fixed 94-character line where position 1 is the Record Type Code. Confirm the record type code and field offsets against the NACHA Operating Rules — don't infer them from analogous records.

## Tradeoffs to surface to the user

- Whether to expose the new record type in the top-level `BankingStandards.ACH` API or keep it internal to the parser.
- Whether to add a separate generator function (write-path) or only a parser (read-path) — existing modules support both; deviating from that is a decision.
