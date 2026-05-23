defmodule BankingStandards.ACH.SecFixturesTest do
  use ExUnit.Case, async: true

  alias BankingStandards.ACH.{Generator, Parser, SecCode, Validator}

  @fixtures_dir "lib/banking_standards/ach/examples/sec"

  # One parser+validator+round-trip test per SEC fixture file, generated at
  # compile time so failures point at the SEC. Fixtures live in
  # lib/banking_standards/ach/examples/sec/*.ach and are regenerated via
  # priv/scripts/regenerate_examples.exs.
  for sec_code <- SecCode.all() do
    @sec_code sec_code
    @fixture_path "#{@fixtures_dir}/#{String.downcase(sec_code)}.ach"

    describe "SEC #{sec_code} fixture" do
      test "parses to an AchFile" do
        assert {:ok, file} = Parser.parse(@fixture_path)
        assert file.header.record_type_code == "1"
        assert file.control.record_type_code == "9"
        [batch] = file.batches
        assert batch.header.standard_entry_class_code == @sec_code
      end

      test "passes cross-record validation" do
        assert {:ok, file} = Parser.parse(@fixture_path)
        assert Validator.validate(file) == :ok
      end

      test "round-trips byte-identically" do
        assert {:ok, file} = Parser.parse(@fixture_path)
        original = File.read!(@fixture_path)
        regenerated = Generator.generate(file)
        assert regenerated == original
      end
    end
  end
end
