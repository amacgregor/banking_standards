defmodule BankingStandards.ACH.EntryDetailTest do
  use ExUnit.Case, async: true
  alias BankingStandards.ACH.EntryDetail

  describe "EntryDetail struct" do
    test "validates successfully with correct data" do
      entry = %EntryDetail{
        record_type_code: "6",
        transaction_code: "27",
        receiving_dfi_identification: "12345678",
        check_digit: "1",
        dfi_account_number: "987654321",
        amount: 100000,
        individual_identification_number: "ID123",
        individual_name: "DOE JOHN",
        discretionary_data: nil,
        addenda_record_indicator: 0,
        trace_number: "0000001"
      }

      assert EntryDetail.validate(entry) == :ok
    end

    test "raises an error for missing required fields" do
      entry = %EntryDetail{
        record_type_code: "6",
        transaction_code: nil,
        receiving_dfi_identification: nil,
        amount: nil
      }

      assert {:error, message} = EntryDetail.validate(entry)
      assert message ==
               "transaction_code is required, receiving_dfi_identification is required, amount must be a positive integer"
    end

    test "raises an error for an invalid record_type_code" do
      entry = %EntryDetail{
        record_type_code: "7",
        transaction_code: "27",
        receiving_dfi_identification: "12345678",
        amount: 100000
      }

      assert {:error, message} = EntryDetail.validate(entry)
      assert message == "Invalid record_type_code"
    end
  end
end
