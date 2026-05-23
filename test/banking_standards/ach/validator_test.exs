defmodule BankingStandards.ACH.ValidatorTest do
  use ExUnit.Case, async: true

  alias BankingStandards.ACH.{
    AchFile,
    Batch,
    BatchHeader,
    BatchTrailer,
    EntryDetail,
    FileControl,
    FileHeader,
    Validator
  }

  # A known-valid ABA routing number (FRB Boston): 011000015 → split into RDFI + check digit.
  @rdfi "01100001"
  @check_digit "5"

  describe "valid_routing_number?/1" do
    test "accepts a valid ABA routing number" do
      assert Validator.valid_routing_number?("011000015")
      assert Validator.valid_routing_number?("021000021")
      assert Validator.valid_routing_number?("076401251")
    end

    test "rejects an invalid ABA routing number" do
      refute Validator.valid_routing_number?("123456789")
      refute Validator.valid_routing_number?("011000016")
    end

    test "rejects non-9-digit input" do
      refute Validator.valid_routing_number?("01100001")
      refute Validator.valid_routing_number?("0110000155")
      refute Validator.valid_routing_number?("01100001X")
      refute Validator.valid_routing_number?("")
      refute Validator.valid_routing_number?(nil)
    end
  end

  describe "validate/1" do
    test "accepts a consistent single-batch file" do
      file = valid_file()
      assert Validator.validate(file) == :ok
    end

    test "rejects tampered batch trailer entry hash" do
      file = valid_file()

      file =
        update_in(file.batches, fn [b] ->
          [%{b | trailer: %{b.trailer | entry_hash: "9999999999"}}]
        end)

      assert {:error, errors} = Validator.validate(file)
      assert Enum.any?(errors, &String.contains?(&1, "Batch trailer entry hash"))
    end

    test "rejects wrong batch trailer total debit" do
      file = valid_file()

      file =
        update_in(file.batches, fn [b] ->
          [%{b | trailer: %{b.trailer | total_debit: b.trailer.total_debit + 1}}]
        end)

      assert {:error, errors} = Validator.validate(file)
      assert Enum.any?(errors, &String.contains?(&1, "Batch trailer total debit"))
    end

    test "rejects wrong file control total credit" do
      file = valid_file()
      file = %{file | control: %{file.control | total_credit: file.control.total_credit + 1}}

      assert {:error, errors} = Validator.validate(file)
      assert Enum.any?(errors, &String.contains?(&1, "File control total credit"))
    end

    test "rejects wrong file control block count" do
      file = valid_file()
      file = %{file | control: %{file.control | block_count: 99}}

      assert {:error, errors} = Validator.validate(file)
      assert Enum.any?(errors, &String.contains?(&1, "File control block count"))
    end

    test "rejects an entry whose routing number fails the ABA check digit" do
      file = valid_file()

      file =
        update_in(file.batches, fn [b] ->
          [
            %{
              b
              | entries:
                  Enum.map(b.entries, fn {entry, addenda} ->
                    {%{entry | receiving_dfi_identification: "12345678", check_digit: "9"},
                     addenda}
                  end)
            }
          ]
        end)

      # Routing-number tampering also breaks the entry hash; we only care that
      # the routing-number rule fires.
      assert {:error, errors} = Validator.validate(file)
      assert Enum.any?(errors, &String.contains?(&1, "Invalid ABA check digit"))
    end
  end

  # Builds a minimal, internally consistent AchFile:
  # 1 batch, 2 credit entries to checking ($100.00 + $50.00 = $150.00).
  defp valid_file do
    entries =
      [
        entry(amount: 10_000, trace_seq: "0000001"),
        entry(amount: 5_000, trace_seq: "0000002")
      ]

    entry_hash = 2 * String.to_integer(@rdfi)

    batch_trailer = %BatchTrailer{
      record_type_code: "8",
      service_class_code: "220",
      entry_addenda_count: 2,
      entry_hash: pad10(entry_hash),
      total_debit: 0,
      total_credit: 15_000,
      company_identification: "1234567890",
      originating_dfi_identification: "07640125",
      batch_number: "0000001"
    }

    batch_header = %BatchHeader{
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

    batch = %Batch{
      header: batch_header,
      entries: entries |> Enum.map(&{&1, []}),
      trailer: batch_trailer
    }

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

    # 1 FH + 1 BH + 2 entries + 1 BT + 1 FC = 6 records → block_count = ceil(6/10) = 1
    file_control = %FileControl{
      record_type_code: "9",
      batch_count: 1,
      block_count: 1,
      entry_addenda_count: 2,
      entry_hash: pad10(entry_hash),
      total_debit: 0,
      total_credit: 15_000
    }

    %AchFile{header: file_header, batches: [batch], control: file_control}
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
      addenda_record_indicator: 0,
      trace_number: "076401251" <> Keyword.fetch!(opts, :trace_seq)
    }
  end

  defp pad10(n), do: n |> Integer.to_string() |> String.pad_leading(10, "0")
end
