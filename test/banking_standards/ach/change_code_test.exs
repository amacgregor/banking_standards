defmodule BankingStandards.ACH.ChangeCodeTest do
  use ExUnit.Case, async: true

  alias BankingStandards.ACH.ChangeCode

  describe "valid?/1" do
    test "accepts known NOC codes" do
      assert ChangeCode.valid?("C01")
      assert ChangeCode.valid?("C05")
      assert ChangeCode.valid?("C14")
    end

    test "rejects unknown codes" do
      refute ChangeCode.valid?("C00")
      refute ChangeCode.valid?("C15")
      refute ChangeCode.valid?("C99")
      refute ChangeCode.valid?("R01")
      refute ChangeCode.valid?("")
      refute ChangeCode.valid?(nil)
    end
  end

  describe "description/1" do
    test "returns descriptions for known codes" do
      assert ChangeCode.description("C01") == "Incorrect DFI Account Number"
      assert ChangeCode.description("C03") == "Incorrect Routing Number and Account Number"
    end

    test "returns nil for unknown codes" do
      assert ChangeCode.description("C99") == nil
    end
  end

  describe "all/0" do
    test "every code from all/0 is itself valid" do
      assert Enum.all?(ChangeCode.all(), &ChangeCode.valid?/1)
    end
  end
end
