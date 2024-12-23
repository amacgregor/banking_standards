defmodule BankingStandards.ACH.ParserTest do
  use ExUnit.Case, async: true
  alias BankingStandards.ACH.Parser

  describe "parse/1" do
    test "parses a valid ACH file" do
      {:ok, result} = Parser.parse("lib/ach/examples/valid.ach")

      assert length(result) > 0
      assert Enum.at(result, 0).__struct__ == BankingStandards.ACH.FileHeader
      assert Enum.at(result, -1).__struct__ == BankingStandards.ACH.FileControl
    end

    test "handles line length error" do
      {:error, error} = Parser.parse("lib/ach/examples/invalid_line_length.ach")
      assert error == "Line length error on line 4"
    end

    test "detects invalid record type" do
      {:error, error} = Parser.parse("lib/ach/examples/invalid_record_type.ach")
      assert error == "Invalid record type '9' on line 3"
    end

    test "parses an ACH file with multiple records" do
      {:ok, result} = Parser.parse("lib/ach/examples/multi_batch.ach")

      assert Enum.count(result, fn record -> record.__struct__ == BankingStandards.ACH.BatchHeader end) == 2
      assert Enum.count(result, fn record -> record.__struct__ == BankingStandards.ACH.EntryDetail end) > 0
      assert Enum.count(result, fn record -> record.__struct__ == BankingStandards.ACH.BatchTrailer end) == 2
    end

    test "returns an error if the file does not exist" do
      assert_raise File.Error, fn ->
        Parser.parse("lib/ach/examples/nonexistent.ach")
      end
    end
  end
end
