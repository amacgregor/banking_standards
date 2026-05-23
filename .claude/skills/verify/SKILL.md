---
name: verify
description: Run the full pre-commit gate for banking_standards — format check, compile-with-warnings-as-errors, tests, credo, ex_dna, dialyzer. Use before committing or opening a PR.
---

Run these checks in order and stop on the first failure. Report which step failed and the relevant output.

1. **Format check** — `mix format --check-formatted`
   - On failure: run `mix format` and re-run the check before continuing.

2. **Compile with warnings as errors** — `mix compile --warnings-as-errors`
   - CI fails on warnings; treat any warning as a blocker.

3. **Tests** — `mix test`

4. **Credo** — `mix credo --strict`
   - This also runs the `ex_slop` plugin checks (configured in `.credo.exs`).
   - Skip with a printed note if the dependency is not yet installed (`mix credo` returns "unknown command").

5. **Duplication detection** — `mix ex_dna`
   - Skip with a printed note if not yet installed. Exit code 1 means clones were found above budget.

6. **Dialyzer** — `mix dialyzer`
   - First run on a fresh `_build` builds PLTs and can take several minutes — that's expected.

Report a one-line summary at the end: which steps ran, which were skipped, which failed.
