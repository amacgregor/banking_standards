defmodule BankingStandards.ACH.ReturnReasonCodeTest do
  use ExUnit.Case, async: true

  alias BankingStandards.ACH.ReturnReasonCode

  describe "valid?/1" do
    test "accepts the common consumer codes" do
      assert ReturnReasonCode.valid?("R01")
      assert ReturnReasonCode.valid?("R02")
      assert ReturnReasonCode.valid?("R10")
    end

    test "accepts IAT-specific codes" do
      assert ReturnReasonCode.valid?("R80")
      assert ReturnReasonCode.valid?("R85")
    end

    test "rejects unknown codes" do
      refute ReturnReasonCode.valid?("R00")
      refute ReturnReasonCode.valid?("R99")
      # R48 / R49 are not assigned (covered range stops at R47 for ENR)
      refute ReturnReasonCode.valid?("R48")
      refute ReturnReasonCode.valid?("")
      refute ReturnReasonCode.valid?(nil)
      refute ReturnReasonCode.valid?("01")
    end
  end

  describe "description/1" do
    test "returns a human-readable description for known codes" do
      assert ReturnReasonCode.description("R01") == "Insufficient Funds"
      assert ReturnReasonCode.description("R02") == "Account Closed"
    end

    test "returns nil for unknown codes" do
      assert ReturnReasonCode.description("R99") == nil
    end
  end

  describe "all/0" do
    test "every code from all/0 is itself valid" do
      assert Enum.all?(ReturnReasonCode.all(), &ReturnReasonCode.valid?/1)
    end
  end
end
