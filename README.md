# BankingStandards

**Tagline:** "Building the foundation for seamless financial transactions in Elixir."

An Elixir library for parsing, generating, and validating financial and payment file standards. Currently ships with NACHA ACH support; Canadian (RTR, Interac, CPA AFT) and ISO 20022 rails are on the roadmap.

## What ships today

NACHA ACH (United States), read **and** write:

- `BankingStandards.ACH.Parser` — `parse/1` reads a file from disk, `parse_string/1` parses an in-memory string. Both return `{:ok, %AchFile{}}` with a hierarchical structure (`AchFile → [Batch → [{EntryDetail, [Addenda]}]]`) or `{:error, reason}` for files with records out of sequence or bad line lengths.
- `BankingStandards.ACH.Generator` — `generate/1` serializes an `AchFile` back to the 94-character fixed-width NACHA format with proper block padding. `write/2` writes the result to a path. Round-trip identity holds (parse → generate → parse).
- `BankingStandards.ACH.Validator` — `validate/1` cross-checks batch trailers and the file control against the actual entries (entry hash, counts, dollar sums, block count) and verifies every routing number's ABA check digit. `valid_routing_number?/1` is exposed for direct use.

Addenda are typed by addenda type code: `Addenda05` (payment-related info), `Addenda02` (POS terminal), `Addenda98` (Notification of Change), `Addenda99` (return). IAT addenda (types 10–18) are not yet supported.

## Roadmap

In priority order:

1. **Full NACHA coverage** — SEC code enum (PPD, CCD, WEB, TEL, CIE, CTX, ARC, BOC, POP, RCK, IAT) with per-SEC validation, transaction code semantics, return entries (R-codes), Notification of Change (C-codes), prenotifications.
2. **ISO 20022 XML foundation** — `saxy`-based parser/generator for ISO 20022 envelopes. Reusable across RTR, future SEPA, future Fedwire ISO migration.
3. **Canadian Real-Time Rail (RTR)** — pacs.008 / pacs.002 / camt.056 messages with the Payments Canada profile constraints layered on top of the generic ISO 20022 modules.
4. **Interac** — research spike to identify what's actually standardized (versus bank-API mediated) before any code lands.
5. **CPA AFT (EFT 005)** — legacy Canadian batch rail, 1464-byte fixed-width records, same hierarchical pattern as ACH.

## Installation

Add `banking_standards` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:banking_standards, "~> 0.1.0"}
  ]
end
```

## Usage

### Parsing

```elixir
alias BankingStandards.ACH.Parser

{:ok, ach_file} = Parser.parse("path/to/file.ach")

ach_file.header.immediate_destination
# => "076401251"

ach_file.batches
|> Enum.flat_map(& &1.entries)
|> Enum.map(fn {entry, _addenda} -> entry.amount end)
# => [10000, 5000, ...]
```

### Generating

```elixir
alias BankingStandards.ACH.Generator

Generator.write(ach_file, "out.ach")
# or, to get the string:
contents = Generator.generate(ach_file)
```

The generator writes trailer and control values verbatim — it does not recompute them. Run `Validator.validate/1` first if values may be inconsistent.

### Validating

```elixir
alias BankingStandards.ACH.Validator

case Validator.validate(ach_file) do
  :ok ->
    :ok

  {:error, errors} ->
    # errors is a list of human-readable strings, one per rule violation
    Enum.each(errors, &IO.puts/1)
end

Validator.valid_routing_number?("011000015")
# => true
```

## Contributing

Issues and PRs welcome. The pre-commit gate is `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test`, `mix credo --strict`, `mix ex_dna`, `mix dialyzer`.

## License

MIT. See the `LICENSE` file.
