defmodule BankingStandards.ACH.AddendaRecordTest do
  use ExUnit.Case, async: true
  alias BankingStandards.ACH.AddendaRecord

  test "validates successfully with correct data" do
    addenda = %AddendaRecord{
      record_type_code: "7",
      addenda_type_code: "05",
      payment_related_information: "SUPPLEMENTAL DATA",
      addenda_sequence_number: 1,
      entry_detail_sequence_number: 1000001
    }

    assert AddendaRecord.validate(addenda) == :ok
  end

  test "raises error for invalid record_type_code" do
    addenda = %AddendaRecord{
      record_type_code: "8",
      addenda_type_code: "05",
      payment_related_information: "SUPPLEMENTAL DATA",
      addenda_sequence_number: 1,
      entry_detail_sequence_number: 1000001
    }

    assert {:error, error} = AddendaRecord.validate(addenda)
    assert error == "Invalid record_type_code"
  end
end
