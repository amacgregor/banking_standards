defmodule BankingStandards.ACH.ParserTest do
  use ExUnit.Case, async: true
  alias BankingStandards.ACH.{AchFile, AddendaRecord, Batch, EntryDetail, Parser}

  describe "parse/1" do
    test "parses a valid ACH file into an AchFile struct" do
      {:ok, %AchFile{} = file} = Parser.parse("lib/banking_standards/ach/examples/valid.ach")

      assert file.header.record_type_code == "1"
      assert file.control.record_type_code == "9"
      assert length(file.batches) == 1

      [%Batch{entries: entries}] = file.batches
      assert length(entries) == 2
      assert Enum.all?(entries, fn {entry, addenda} -> match?(%EntryDetail{}, entry) and addenda == [] end)
    end

    test "associates addenda with their preceding entry" do
      {:ok, %AchFile{batches: [%Batch{entries: entries}]}} =
        Parser.parse("lib/banking_standards/ach/examples/entry_addenda.ach")

      assert length(entries) == 2

      Enum.each(entries, fn {%EntryDetail{} = entry, addenda} ->
        assert [%AddendaRecord{} = a] = addenda
        assert a.entry_detail_sequence_number ==
                 entry.trace_number |> String.slice(-7..-1) |> String.to_integer()
      end)
    end

    test "handles line length error" do
      {:error, error} = Parser.parse("lib/banking_standards/ach/examples/invalid_line_length.ach")
      assert error == "Line length error on line 4"
    end

    test "detects invalid record type" do
      {:error, error} = Parser.parse("lib/banking_standards/ach/examples/invalid_record_type.ach")
      assert error == "Invalid record type '901' on line 3"
    end

    test "rejects records out of sequence" do
      # multi_batch.ach has an entry detail + addenda orphaned after the second
      # batch trailer with no new batch header. The hierarchical parser rejects
      # this; a fixed multi_batch fixture is added in the generator commit.
      {:error, error} = Parser.parse("lib/banking_standards/ach/examples/multi_batch.ach")
      assert error =~ "Expected batch header or file control, got entry detail"
    end

    test "raises if the file does not exist" do
      assert_raise File.Error, fn ->
        Parser.parse("lib/banking_standards/ach/examples/nonexistent.ach")
      end
    end
  end
end
