defmodule BankingStandards.ACH.BatchTrailerTest do
  use ExUnit.Case, async: true
  alias BankingStandards.ACH.BatchTrailer

  describe "BatchTrailer struct" do
    test "validates successfully with correct data" do
      trailer = %BatchTrailer{
        record_type_code: "8",
        service_class_code: "200",
        entry_addenda_count: 5,
        entry_hash: "123456789",
        total_debit: 100000,
        total_credit: 100000,
        company_identification: "987654321",
        originating_dfi_identification: "076401251",
        batch_number: "0000001"
      }

      assert BatchTrailer.validate(trailer) == :ok
    end

    test "raises an error for missing required fields" do
      trailer = %BatchTrailer{
        record_type_code: "8",
        total_debit: nil,
        total_credit: nil
      }

      assert {:error, message} = BatchTrailer.validate(trailer)
      assert message == "total_debit is required, total_credit is required"
    end

    test "raises an error for an invalid record_type_code" do
      trailer = %BatchTrailer{
        record_type_code: "9",
        total_debit: 100000,
        total_credit: 100000
      }

      assert {:error, message} = BatchTrailer.validate(trailer)
      assert message == "Invalid record_type_code"
    end
  end
end
