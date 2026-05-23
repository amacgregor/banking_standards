defmodule BankingStandards.ACH.TransactionCodeTest do
  use ExUnit.Case, async: true

  alias BankingStandards.ACH.TransactionCode

  describe "valid?/1" do
    test "accepts every known code" do
      assert Enum.all?(TransactionCode.all(), &TransactionCode.valid?/1)
    end

    test "rejects unknown codes" do
      refute TransactionCode.valid?("00")
      refute TransactionCode.valid?("99")
      refute TransactionCode.valid?("21")
      refute TransactionCode.valid?("")
      refute TransactionCode.valid?(nil)
    end
  end

  describe "direction/1, account_type/1, kind/1" do
    test "decodes 22 as a live credit to checking" do
      assert TransactionCode.direction("22") == :credit
      assert TransactionCode.account_type("22") == :checking
      assert TransactionCode.kind("22") == :live
    end

    test "decodes 28 as a checking debit prenote" do
      assert TransactionCode.direction("28") == :debit
      assert TransactionCode.account_type("28") == :checking
      assert TransactionCode.kind("28") == :prenote
    end

    test "decodes 32 as a live credit to savings" do
      assert TransactionCode.account_type("32") == :savings
      assert TransactionCode.direction("32") == :credit
      assert TransactionCode.kind("32") == :live
    end

    test "decodes 47 as a live debit to general ledger" do
      assert TransactionCode.account_type("47") == :general_ledger
      assert TransactionCode.direction("47") == :debit
      assert TransactionCode.kind("47") == :live
    end

    test "decodes 55 as a live debit to loan" do
      assert TransactionCode.account_type("55") == :loan
      assert TransactionCode.direction("55") == :debit
      assert TransactionCode.kind("55") == :live
    end

    test "returns nil for an unknown code" do
      assert TransactionCode.direction("99") == nil
      assert TransactionCode.account_type("99") == nil
      assert TransactionCode.kind("99") == nil
    end
  end

  describe "predicates" do
    test "prenote?/1 picks out only the prenote codes" do
      assert TransactionCode.prenote?("23")
      assert TransactionCode.prenote?("28")
      assert TransactionCode.prenote?("33")
      assert TransactionCode.prenote?("38")
      assert TransactionCode.prenote?("43")
      assert TransactionCode.prenote?("48")
      assert TransactionCode.prenote?("53")
      refute TransactionCode.prenote?("22")
      refute TransactionCode.prenote?("24")
      refute TransactionCode.prenote?("99")
    end

    test "credit?/1 and debit?/1 are mutually exclusive on known codes" do
      Enum.each(TransactionCode.all(), fn code ->
        c = TransactionCode.credit?(code)
        d = TransactionCode.debit?(code)
        assert c != d, "code #{code}: credit?=#{c}, debit?=#{d}"
      end)
    end
  end
end
