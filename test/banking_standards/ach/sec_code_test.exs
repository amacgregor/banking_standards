defmodule BankingStandards.ACH.SecCodeTest do
  use ExUnit.Case, async: true

  alias BankingStandards.ACH.SecCode

  describe "valid?/1" do
    test "accepts every modelled SEC code" do
      assert Enum.all?(SecCode.all(), &SecCode.valid?/1)
    end

    test "rejects IAT (deferred to PR 3c)" do
      refute SecCode.valid?("IAT")
    end

    test "rejects unknown codes" do
      refute SecCode.valid?("XYZ")
      refute SecCode.valid?("")
      refute SecCode.valid?(nil)
    end
  end

  describe "allowed_transaction_codes/1" do
    test "PPD allows credits and debits to checking and savings" do
      codes = SecCode.allowed_transaction_codes("PPD")
      assert "22" in codes and "27" in codes and "32" in codes and "37" in codes
    end

    test "POP and RCK only allow live debits (no prenotes, no credits)" do
      assert SecCode.allowed_transaction_codes("POP") == ~w(27 37)
      assert SecCode.allowed_transaction_codes("RCK") == ~w(27 37)
    end

    test "CIE is credit-only" do
      codes = SecCode.allowed_transaction_codes("CIE")
      assert "22" in codes
      refute "27" in codes
    end

    test "TEL is debit-only" do
      codes = SecCode.allowed_transaction_codes("TEL")
      refute "22" in codes
      assert "27" in codes
    end

    test "returns nil for unknown SECs" do
      assert SecCode.allowed_transaction_codes("IAT") == nil
      assert SecCode.allowed_transaction_codes("XYZ") == nil
    end
  end

  describe "addenda_range/1" do
    test "PPD/CCD/WEB/TEL allow at most one addenda" do
      Enum.each(~w(PPD CCD WEB TEL), fn sec ->
        assert SecCode.addenda_range(sec) == {0, 1}, "expected 0..1 for #{sec}"
      end)
    end

    test "CTX and CIE allow up to 9999 addenda" do
      assert SecCode.addenda_range("CTX") == {0, 9999}
      assert SecCode.addenda_range("CIE") == {0, 9999}
    end

    test "ARC/BOC/POP/RCK forbid addenda" do
      Enum.each(~w(ARC BOC POP RCK), fn sec ->
        assert SecCode.addenda_range(sec) == {0, 0}, "expected 0..0 for #{sec}"
      end)
    end

    test "returns nil for unknown SECs" do
      assert SecCode.addenda_range("IAT") == nil
    end
  end

  describe "allowed_addenda_types/1" do
    test "SECs that allow addenda only permit type 05" do
      Enum.each(~w(PPD CCD CIE CTX WEB TEL), fn sec ->
        assert SecCode.allowed_addenda_types(sec) == ["05"], "expected [05] for #{sec}"
      end)
    end

    test "SECs that forbid addenda return an empty type list" do
      Enum.each(~w(ARC BOC POP RCK), fn sec ->
        assert SecCode.allowed_addenda_types(sec) == [], "expected [] for #{sec}"
      end)
    end
  end

  describe "registry sanity" do
    test "every transaction code in any spec is a known TransactionCode" do
      assert SecCode.all_transaction_codes_known?()
    end
  end
end
