# Regenerates the example .ach fixtures using BankingStandards.ACH.Generator
# so they have internally consistent trailer/control values. Run with:
#
#   mix run priv/scripts/regenerate_examples.exs

alias BankingStandards.ACH.{
  AchFile,
  Addenda05,
  Batch,
  BatchHeader,
  BatchTrailer,
  EntryDetail,
  FileControl,
  FileHeader,
  Generator,
  Validator
}

# Known-valid routing numbers (real Fed routing numbers, used for testing).
rdfi = "01100001"
check_digit = "5"
rdfi_int = String.to_integer(rdfi)

file_header = %FileHeader{
  record_type_code: "1",
  priority_code: "01",
  immediate_destination: "076401251",
  immediate_origin: "1234567890",
  file_creation_date: "260523",
  file_creation_time: "1200",
  file_id_modifier: "A",
  record_size: "094",
  blocking_factor: "10",
  format_code: "1",
  immediate_destination_name: "DEST BANK",
  immediate_origin_name: "ACME COMPANY"
}

build_entry = fn amount, trace_seq, addenda_indicator ->
  %EntryDetail{
    record_type_code: "6",
    transaction_code: "22",
    receiving_dfi_identification: rdfi,
    check_digit: check_digit,
    dfi_account_number: "987654321",
    amount: amount,
    individual_identification_number: "",
    individual_name: "DOE JOHN",
    discretionary_data: "",
    addenda_record_indicator: addenda_indicator,
    trace_number: "07640125" <> trace_seq
  }
end

pad10 = fn n -> n |> Integer.to_string() |> String.pad_leading(10, "0") end

# -- valid.ach: 1 batch, 2 simple entries --
valid_entries = [
  {build_entry.(50_000, "0000001", 0), []},
  {build_entry.(75_000, "0000002", 0), []}
]

valid_file = %AchFile{
  header: file_header,
  batches: [
    %Batch{
      header: %BatchHeader{
        record_type_code: "5",
        service_class_code: "220",
        company_name: "ACME",
        company_discretionary_data: "",
        company_identification: "1234567890",
        standard_entry_class_code: "PPD",
        company_entry_description: "PAYROLL",
        company_descriptive_date: "260523",
        effective_entry_date: "260524",
        settlement_date: "",
        originator_status_code: "1",
        originating_dfi_identification: "07640125",
        batch_number: "0000001"
      },
      entries: valid_entries,
      trailer: %BatchTrailer{
        record_type_code: "8",
        service_class_code: "220",
        entry_addenda_count: 2,
        entry_hash: pad10.(2 * rdfi_int),
        total_debit: 0,
        total_credit: 125_000,
        company_identification: "1234567890",
        originating_dfi_identification: "07640125",
        batch_number: "0000001"
      }
    }
  ],
  control: %FileControl{
    record_type_code: "9",
    batch_count: 1,
    block_count: 1,
    entry_addenda_count: 2,
    entry_hash: pad10.(2 * rdfi_int),
    total_debit: 0,
    total_credit: 125_000
  }
}

# -- entry_addenda.ach: 1 batch, 2 entries each with an Addenda05 --
addenda_entries = [
  {
    build_entry.(50_000, "0000001", 1),
    [
      %Addenda05{
        record_type_code: "7",
        addenda_type_code: "05",
        payment_related_information: "SUPPLEMENTAL INFORMATION 1",
        addenda_sequence_number: 1,
        entry_detail_sequence_number: 1
      }
    ]
  },
  {
    build_entry.(75_000, "0000002", 1),
    [
      %Addenda05{
        record_type_code: "7",
        addenda_type_code: "05",
        payment_related_information: "SUPPLEMENTAL INFORMATION 2",
        addenda_sequence_number: 1,
        entry_detail_sequence_number: 2
      }
    ]
  }
]

addenda_file = %{
  valid_file
  | batches: [
      %{
        hd(valid_file.batches)
        | entries: addenda_entries,
          trailer: %{hd(valid_file.batches).trailer | entry_addenda_count: 4}
      }
    ],
    control: %{valid_file.control | entry_addenda_count: 4}
}

# -- multi_batch.ach: 2 batches --
batch_2 = %Batch{
  header: %BatchHeader{
    record_type_code: "5",
    service_class_code: "225",
    company_name: "ACME",
    company_discretionary_data: "",
    company_identification: "1234567890",
    standard_entry_class_code: "PPD",
    company_entry_description: "INVOICES",
    company_descriptive_date: "260523",
    effective_entry_date: "260524",
    settlement_date: "",
    originator_status_code: "1",
    originating_dfi_identification: "07640125",
    batch_number: "0000002"
  },
  entries: [
    {build_entry.(20_000, "0000003", 0) |> Map.put(:transaction_code, "27"), []},
    {build_entry.(30_000, "0000004", 0) |> Map.put(:transaction_code, "27"), []}
  ],
  trailer: %BatchTrailer{
    record_type_code: "8",
    service_class_code: "225",
    entry_addenda_count: 2,
    entry_hash: pad10.(2 * rdfi_int),
    total_debit: 50_000,
    total_credit: 0,
    company_identification: "1234567890",
    originating_dfi_identification: "07640125",
    batch_number: "0000002"
  }
}

multi_batch_file = %{
  valid_file
  | batches: valid_file.batches ++ [batch_2],
    control: %{
      valid_file.control
      | batch_count: 2,
        entry_addenda_count: 4,
        entry_hash: pad10.(rem(4 * rdfi_int, 10_000_000_000)),
        total_debit: 50_000,
        total_credit: 125_000
    }
}

# Write all three.
targets = [
  {"lib/banking_standards/ach/examples/valid.ach", valid_file},
  {"lib/banking_standards/ach/examples/entry_addenda.ach", addenda_file},
  {"lib/banking_standards/ach/examples/multi_batch.ach", multi_batch_file}
]

Enum.each(targets, fn {path, file} ->
  case Validator.validate(file) do
    :ok ->
      :ok = Generator.write(file, path)
      IO.puts("✓ wrote #{path}")

    {:error, errors} ->
      IO.puts("✗ #{path} failed validation:")
      Enum.each(errors, &IO.puts("    - #{&1}"))
      System.halt(1)
  end
end)
