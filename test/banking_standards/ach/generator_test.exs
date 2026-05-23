defmodule BankingStandards.ACH.GeneratorTest do
  use ExUnit.Case, async: true

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
    Validator
  }

  @rdfi "01100001"
  @check_digit "5"

  describe "generate/1" do
    test "every line is exactly 94 characters" do
      output = Generator.generate(sample_file())

      lines = String.split(output, "\n", trim: true)
      assert Enum.all?(lines, &(String.length(&1) == 94))
    end

    test "pads the file to a multiple of 10 records with 9-records" do
      output = Generator.generate(sample_file())

      lines = String.split(output, "\n", trim: true)
      assert rem(length(lines), 10) == 0

      # Without addenda: 1 FH + 1 BH + 2 ED + 1 BT + 1 FC = 6 records, padded to 10.
      assert length(lines) == 10
      padding = String.duplicate("9", 94)
      assert Enum.count(lines, &(&1 == padding)) == 4
    end

    test "round-trips: parse(generate(file)) == file" do
      original = sample_file()
      {:ok, reparsed} = original |> Generator.generate() |> Parser.parse_string()

      assert reparsed == original
    end

    test "round-trips a file with Addenda05 records" do
      original = sample_file_with_addenda()
      {:ok, reparsed} = original |> Generator.generate() |> Parser.parse_string()

      assert reparsed == original
    end

    test "generated file passes cross-record validation" do
      output = Generator.generate(sample_file())
      {:ok, parsed} = Parser.parse_string(output)

      assert Validator.validate(parsed) == :ok
    end
  end

  # 1 batch, 2 credit-to-checking entries of $100 and $50.
  defp sample_file do
    entries = [
      {entry(amount: 10_000, trace_seq: "0000001"), []},
      {entry(amount: 5_000, trace_seq: "0000002"), []}
    ]

    %AchFile{
      header: file_header(),
      batches: [%Batch{header: batch_header(), entries: entries, trailer: batch_trailer(2)}],
      control: file_control(2)
    }
  end

  defp sample_file_with_addenda do
    addenda = %Addenda05{
      record_type_code: "7",
      addenda_type_code: "05",
      payment_related_information: "INVOICE 12345",
      addenda_sequence_number: 1,
      entry_detail_sequence_number: 1
    }

    entries = [
      {entry(amount: 10_000, trace_seq: "0000001", addenda_indicator: 1), [addenda]},
      {entry(amount: 5_000, trace_seq: "0000002"), []}
    ]

    %AchFile{
      header: file_header(),
      batches: [%Batch{header: batch_header(), entries: entries, trailer: batch_trailer(3)}],
      control: file_control(3)
    }
  end

  defp file_header do
    %FileHeader{
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
  end

  defp batch_header do
    %BatchHeader{
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
    }
  end

  defp batch_trailer(entry_addenda_count) do
    %BatchTrailer{
      record_type_code: "8",
      service_class_code: "220",
      entry_addenda_count: entry_addenda_count,
      entry_hash: pad10(2 * String.to_integer(@rdfi)),
      total_debit: 0,
      total_credit: 15_000,
      company_identification: "1234567890",
      originating_dfi_identification: "07640125",
      batch_number: "0000001"
    }
  end

  defp file_control(entry_addenda_count) do
    %FileControl{
      record_type_code: "9",
      batch_count: 1,
      block_count: 1,
      entry_addenda_count: entry_addenda_count,
      entry_hash: pad10(2 * String.to_integer(@rdfi)),
      total_debit: 0,
      total_credit: 15_000
    }
  end

  defp entry(opts) do
    %EntryDetail{
      record_type_code: "6",
      transaction_code: "22",
      receiving_dfi_identification: @rdfi,
      check_digit: @check_digit,
      dfi_account_number: "123456789",
      amount: Keyword.fetch!(opts, :amount),
      individual_identification_number: "",
      individual_name: "DOE JOHN",
      discretionary_data: "",
      addenda_record_indicator: Keyword.get(opts, :addenda_indicator, 0),
      trace_number: "07640125" <> Keyword.fetch!(opts, :trace_seq)
    }
  end

  defp pad10(n), do: n |> Integer.to_string() |> String.pad_leading(10, "0")
end
