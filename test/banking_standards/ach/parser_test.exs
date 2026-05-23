defmodule BankingStandards.ACH.ParserTest do
  use ExUnit.Case, async: true
  alias BankingStandards.ACH.{AchFile, Addenda05, Batch, EntryDetail, Parser}

  describe "parse/1" do
    test "parses a valid ACH file into an AchFile struct" do
      {:ok, %AchFile{} = file} = Parser.parse("lib/banking_standards/ach/examples/valid.ach")

      assert file.header.record_type_code == "1"
      assert file.control.record_type_code == "9"
      assert length(file.batches) == 1

      [%Batch{entries: entries}] = file.batches
      assert length(entries) == 2

      assert Enum.all?(entries, fn {entry, addenda} ->
               match?(%EntryDetail{}, entry) and addenda == []
             end)
    end

    test "associates addenda with their preceding entry" do
      {:ok, %AchFile{batches: [%Batch{entries: entries}]}} =
        Parser.parse("lib/banking_standards/ach/examples/entry_addenda.ach")

      assert length(entries) == 2

      Enum.each(entries, fn {%EntryDetail{} = entry, addenda} ->
        assert [%Addenda05{} = a] = addenda

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

    test "parses a multi-batch file with consistent trailers and control" do
      {:ok, %AchFile{batches: batches, control: control}} =
        Parser.parse("lib/banking_standards/ach/examples/multi_batch.ach")

      assert length(batches) == 2
      assert control.batch_count == 2
    end

    test "raises if the file does not exist" do
      assert_raise File.Error, fn ->
        Parser.parse("lib/banking_standards/ach/examples/nonexistent.ach")
      end
    end
  end

  describe "parse_string/1" do
    test "parses an in-memory ACH file string" do
      content = File.read!("lib/banking_standards/ach/examples/valid.ach")
      {:ok, %AchFile{}} = Parser.parse_string(content)
    end

    test "rejects an entry detail outside any batch" do
      # File header, then an entry detail with no batch header in between.
      lines = [
        String.pad_trailing(
          "101 076401251 1234567890260523120010094101DEST                   ORIG",
          94
        ),
        String.pad_trailing(
          "6220110000159876543210000010000               DOE JOHN              0076401250000001",
          94
        )
      ]

      content = Enum.join(lines, "\n") <> "\n"
      assert {:error, error} = Parser.parse_string(content)
      assert error =~ "Expected batch header or file control, got entry detail"
    end
  end
end
