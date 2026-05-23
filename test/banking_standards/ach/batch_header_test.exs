defmodule BankingStandards.ACH.BatchHeaderTest do
  use ExUnit.Case, async: true
  alias BankingStandards.ACH.BatchHeader

  describe "BatchHeader struct" do
    test "initializes with valid data" do
      header = %BatchHeader{
        record_type_code: "5",
        service_class_code: "200",
        company_name: "Your Company Name",
        company_discretionary_data: "Optional Data",
        company_identification: "987654321",
        standard_entry_class_code: "PPD",
        company_entry_description: "Payroll",
        company_descriptive_date: "20230101",
        effective_entry_date: "20230102",
        settlement_date: "123",
        originator_status_code: "1",
        originating_dfi_identification: "076401251",
        batch_number: "0000001"
      }

      assert BatchHeader.validate(header) == :ok
    end

    test "raises an error for missing required fields" do
      header = %BatchHeader{
        record_type_code: "5",
        company_name: nil,
        company_identification: nil
      }

      assert {:error, message} = BatchHeader.validate(header)
      assert message == "company_name is required, company_identification is required"
    end
  end
end
