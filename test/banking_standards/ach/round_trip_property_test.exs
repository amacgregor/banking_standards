defmodule BankingStandards.ACH.RoundTripPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

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
    Parser,
    SecCode,
    TransactionCode,
    Validator
  }

  # ABA-valid routing numbers, RDFI (8 chars) and check digit (1 char).
  @routing_numbers [
    {"01100001", "5"},
    {"02100002", "1"},
    {"07640125", "1"}
  ]

  @hash_modulus 10_000_000_000

  # One property per SEC so failures point at the SEC. Each runs 30 times —
  # 10 SECs × 30 runs × 2 properties = 600 total runs, plenty for coverage
  # without blowing out the test wall-clock.
  for sec_code <- SecCode.all() do
    @sec_code sec_code

    describe "parse_string ∘ generate for SEC #{sec_code}" do
      property "round-trips identically" do
        check all(file <- ach_file_gen(@sec_code), max_runs: 30) do
          generated = Generator.generate(file)
          {:ok, reparsed} = Parser.parse_string(generated)
          assert reparsed == file
        end
      end

      property "passes cross-record validation" do
        check all(file <- ach_file_gen(@sec_code), max_runs: 30) do
          generated = Generator.generate(file)
          {:ok, reparsed} = Parser.parse_string(generated)
          assert Validator.validate(reparsed) == :ok
        end
      end
    end
  end

  defp ach_file_gen(sec_code) do
    {_min, max} = SecCode.addenda_range(sec_code)
    capped_max = min(max, 3)

    gen all(
          batch_entry_specs <-
            list_of(
              list_of(entry_spec_gen(sec_code, capped_max), min_length: 1, max_length: 4),
              min_length: 1,
              max_length: 3
            )
        ) do
      build_ach_file(sec_code, batch_entry_specs)
    end
  end

  defp entry_spec_gen(sec_code, max_addenda) do
    # Exclude prenote codes — they require amount=0, which would make our
    # positive-amount generator invalid. They're covered by explicit unit tests.
    allowed =
      sec_code
      |> SecCode.allowed_transaction_codes()
      |> Enum.reject(&TransactionCode.prenote?/1)

    gen all(
          {rdfi, check_digit} <- member_of(@routing_numbers),
          amount <- integer(1..999_999_999),
          transaction_code <- member_of(allowed),
          addenda_count <- integer(0..max_addenda)
        ) do
      %{
        rdfi: rdfi,
        check_digit: check_digit,
        amount: amount,
        transaction_code: transaction_code,
        addenda_count: addenda_count
      }
    end
  end

  defp build_ach_file(sec_code, batch_entry_specs) do
    batches =
      batch_entry_specs
      |> Enum.with_index(1)
      |> Enum.map(fn {entry_specs, batch_idx} ->
        build_batch(sec_code, entry_specs, batch_idx)
      end)

    total_entry_addenda = Enum.sum(Enum.map(batches, & &1.trailer.entry_addenda_count))

    total_entry_hash =
      batches
      |> Enum.map(fn b -> String.to_integer(b.trailer.entry_hash) end)
      |> Enum.sum()
      |> rem(@hash_modulus)

    {total_debit, total_credit} =
      Enum.reduce(batches, {0, 0}, fn b, {td, tc} ->
        {td + b.trailer.total_debit, tc + b.trailer.total_credit}
      end)

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

    # Records on disk: 1 FH + sum_of_batches(1 BH + N entries + M addenda + 1 BT) + 1 FC
    record_count =
      1 + 1 +
        Enum.reduce(batches, 0, fn b, acc -> acc + 2 + b.trailer.entry_addenda_count end)

    file_control = %FileControl{
      record_type_code: "9",
      batch_count: length(batches),
      block_count: div(record_count + 9, 10),
      entry_addenda_count: total_entry_addenda,
      entry_hash: pad10(total_entry_hash),
      total_debit: total_debit,
      total_credit: total_credit
    }

    %AchFile{header: file_header, batches: batches, control: file_control}
  end

  defp build_batch(sec_code, entry_specs, batch_idx) do
    entries = build_entries(entry_specs)
    {total_debit, total_credit} = sum_amounts(entries)
    service_class_code = service_class_code(total_debit, total_credit)
    batch_number = String.pad_leading(Integer.to_string(batch_idx), 7, "0")

    %Batch{
      header: batch_header(sec_code, service_class_code, batch_number),
      entries: entries,
      trailer: %BatchTrailer{
        record_type_code: "8",
        service_class_code: service_class_code,
        entry_addenda_count: count_entries_and_addenda(entries),
        entry_hash: pad10(entry_hash(entries)),
        total_debit: total_debit,
        total_credit: total_credit,
        company_identification: "1234567890",
        originating_dfi_identification: "07640125",
        batch_number: batch_number
      }
    }
  end

  defp build_entries(entry_specs) do
    entry_specs
    |> Enum.with_index(1)
    |> Enum.map(fn {spec, entry_idx} ->
      {build_entry(spec, entry_idx), build_addenda(spec, entry_idx)}
    end)
  end

  defp build_entry(spec, entry_idx) do
    trace_seq = String.pad_leading(Integer.to_string(entry_idx), 7, "0")

    %EntryDetail{
      record_type_code: "6",
      transaction_code: spec.transaction_code,
      receiving_dfi_identification: spec.rdfi,
      check_digit: spec.check_digit,
      dfi_account_number: "987654321",
      amount: spec.amount,
      individual_identification_number: "",
      individual_name: "DOE JOHN",
      discretionary_data: "",
      addenda_record_indicator: if(spec.addenda_count > 0, do: 1, else: 0),
      trace_number: "07640125" <> trace_seq
    }
  end

  defp build_addenda(%{addenda_count: 0}, _entry_idx), do: []

  defp build_addenda(%{addenda_count: count}, entry_idx) do
    for seq <- 1..count do
      %Addenda05{
        record_type_code: "7",
        addenda_type_code: "05",
        payment_related_information: "TEST PAYMENT INFO #{seq}",
        addenda_sequence_number: seq,
        entry_detail_sequence_number: entry_idx
      }
    end
  end

  defp batch_header(sec_code, service_class_code, batch_number) do
    %BatchHeader{
      record_type_code: "5",
      service_class_code: service_class_code,
      company_name: "ACME",
      company_discretionary_data: "",
      company_identification: "1234567890",
      standard_entry_class_code: sec_code,
      company_entry_description: "PAYROLL",
      company_descriptive_date: "260523",
      effective_entry_date: "260524",
      settlement_date: "",
      originator_status_code: "1",
      originating_dfi_identification: "07640125",
      batch_number: batch_number
    }
  end

  defp count_entries_and_addenda(entries) do
    Enum.reduce(entries, 0, fn {_e, addenda}, acc -> acc + 1 + length(addenda) end)
  end

  defp entry_hash(entries) do
    entries
    |> Enum.map(fn {%EntryDetail{} = e, _} ->
      String.to_integer(e.receiving_dfi_identification)
    end)
    |> Enum.sum()
    |> rem(@hash_modulus)
  end

  defp sum_amounts(entries) do
    Enum.reduce(entries, {0, 0}, fn {%EntryDetail{} = e, _}, {td, tc} ->
      case TransactionCode.direction(e.transaction_code) do
        :credit -> {td, tc + e.amount}
        :debit -> {td + e.amount, tc}
        nil -> {td, tc}
      end
    end)
  end

  defp service_class_code(debit, credit) do
    cond do
      debit > 0 and credit > 0 -> "200"
      credit > 0 -> "220"
      debit > 0 -> "225"
      true -> "200"
    end
  end

  defp pad10(n), do: n |> Integer.to_string() |> String.pad_leading(10, "0")
end
