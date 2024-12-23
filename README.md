# BankingStandards

**Tagline:** "Building the foundation for seamless financial transactions in Elixir."

BankingStandards is an Elixir library dedicated to providing robust tools and utilities for managing financial and payment file standards. Our mission is to empower developers with reliable, extensible, and standards-compliant solutions for handling complex banking workflows. We envision a future where integrating banking and payment systems into Elixir applications is as seamless and straightforward as possible.

This library is designed to be the cornerstone of financial technology in Elixir, starting with NACHA ACH standards and expanding to include a comprehensive suite of tools for global banking protocols. By prioritizing usability, compliance, and extensibility, BankingStandards aims to bridge the gap between financial complexity and developer productivity.

## Features

- **ACH.Parser**: Parse NACHA ACH files into structured Elixir data.
- **ACH.Generator**: Generate NACHA ACH-compliant files from structured data.
- **ACH.Validator**: Validate ACH files or data against NACHA compliance rules.
- Planned support for:
  - CPA AFT (Canada)
  - ISO 20022 (International)

## Common Standards

### NACHA ACH (USA)
The NACHA ACH standard is the backbone of electronic payments in the United States, enabling direct deposits, vendor payments, and tax remittances. BankingStandards provides tools for parsing, generating, and validating ACH files to ensure compliance with NACHA rules.

### CPA AFT (Canada)
The CPA AFT standard is widely used in Canada for electronic funds transfers, such as payroll and CRA payments. Future updates to BankingStandards will include modules for parsing and generating CPA AFT files.

### ISO 20022 (International)
ISO 20022 is a global standard for electronic data interchange between financial institutions. It is widely adopted for international transactions, including SEPA payments in Europe and cross-border wire transfers. BankingStandards will include tools for working with ISO 20022 XML-based schemas.

### EDI 820
A common standard for electronic payment orders and remittance advice, used primarily in B2B transactions. Planned support for EDI standards will enhance BankingStandards' utility in corporate finance.

## Installation

Add `banking_standards` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:banking_standards, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Usage

### Parsing ACH Files

```elixir
alias BankingStandards.ACH.Parser

{:ok, data} = Parser.parse("path/to/file.ach")
data |> IO.inspect()
```

### Generating ACH Files

```elixir
alias BankingStandards.ACH.Generator

Generator.generate("output.ach", [
  %BatchHeader{company_name: "My Company", service_code: "200"},
  %EntryDetail{account_number: "12345678", transaction_code: "27", amount: 100000},
  %BatchTrailer{entry_addenda_count: 1, total_debit: 100000}
])
```

### Validating ACH Files

```elixir
alias BankingStandards.ACH.Validator

{:ok, data} = Validator.validate_file("path/to/file.ach")
{:ok, data} = Validator.validate_data([
  %BatchHeader{company_name: "My Company", service_code: "200"},
  %EntryDetail{account_number: "12345678", transaction_code: "27", amount: 100000}
])
```

## Project Structure

```plaintext
BankingStandards/
├── README.md                # Project overview and usage examples
├── LICENSE                  # Open source license
├── .gitignore               # Git ignore rules
├── mix.exs                  # Elixir project configuration
├── config/                  # Elixir application configuration
├── lib/
│   ├── banking_standards.ex # Main module
│   ├── ach/                 # NACHA ACH standards
│   │   ├── parser.ex        # ACH file parser
│   │   ├── generator.ex     # ACH file generator
│   │   ├── validator.ex     # ACH file validator
│   │   ├── examples/        # Example ACH files
│   │   └── docs/            # ACH documentation and specs
│   ├── aft/                 # CPA AFT standards
│   │   ├── parser.ex        # AFT file parser
│   │   ├── generator.ex     # AFT file generator
│   │   ├── validator.ex     # AFT file validator
│   │   ├── examples/        # Example AFT files
│   │   └── docs/            # AFT documentation and specs
│   ├── iso20022/            # ISO 20022 standards
│   │   ├── parser.ex        # ISO 20022 XML parser
│   │   ├── generator.ex     # ISO 20022 message generator
│   │   ├── validator.ex     # ISO 20022 validator
│   │   ├── schemas/         # Predefined XML schemas
│   │   ├── examples/        # Example ISO 20022 files
│   │   └── docs/            # ISO 20022 documentation and specs
│   └── common/              # Shared utilities
│       ├── file_helper.ex   # File reading and writing utilities
│       ├── validations.ex   # Common validation functions
│       ├── format_helper.ex # Helper functions for formatting
│       └── docs/            # Shared utilities documentation
├── test/                    # Test suite
│   ├── ach_test.exs         # Tests for ACH standards
│   ├── aft_test.exs         # Tests for AFT standards
│   ├── iso20022_test.exs    # Tests for ISO 20022 standards
│   └── common_test.exs      # Tests for shared utilities
└── docs/                    # Project-level documentation
    ├── architecture.md      # High-level architecture overview
    ├── CONTRIBUTING.md      # Contribution guidelines
    ├── FAQ.md               # Frequently asked questions
    └── ROADMAP.md           # Project roadmap and future features
```

## Contributing

We welcome contributions! Please see the `CONTRIBUTING.md` file in the `docs/` folder for guidelines.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

