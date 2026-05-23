defmodule BankingStandards.ACH.Validator do
  @moduledoc """
  Cross-record validation for a parsed `AchFile`.

  Verifies that the trailer-level totals, hashes, and counts are consistent
  with the entries they bound, and that routing numbers carry valid ABA
  check digits. Returns `:ok` or `{:error, [reason, ...]}` — all rules
  are evaluated; errors are not short-circuited.
  """

  alias BankingStandards.ACH.{
    AchFile,
    Addenda98,
    Addenda99,
    Batch,
    ChangeCode,
    EntryDetail,
    ReturnReasonCode,
    TransactionCode
  }

  @hash_modulus 10_000_000_000

  @spec validate(AchFile.t()) :: :ok | {:error, [String.t()]}
  def validate(%AchFile{} = file) do
    errors =
      validate_routing_numbers(file) ++
        validate_transaction_codes(file) ++
        validate_addenda_codes(file) ++
        validate_batch_trailers(file) ++
        validate_file_control(file)

    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @doc """
  Verifies a 9-digit ABA routing number's check digit.

  The check digit (position 9) makes the weighted sum 3·d1 + 7·d2 + 1·d3
  + 3·d4 + 7·d5 + 1·d6 + 3·d7 + 7·d8 + 1·d9 a multiple of 10.
  """
  @spec valid_routing_number?(String.t()) :: boolean()
  def valid_routing_number?(rt) when is_binary(rt) do
    case String.to_charlist(rt) do
      [_, _, _, _, _, _, _, _, _] = chars ->
        if Enum.all?(chars, &(&1 >= ?0 and &1 <= ?9)) do
          [d1, d2, d3, d4, d5, d6, d7, d8, d9] = Enum.map(chars, &(&1 - ?0))

          sum =
            3 * d1 + 7 * d2 + 1 * d3 + 3 * d4 + 7 * d5 + 1 * d6 + 3 * d7 + 7 * d8 + 1 * d9

          rem(sum, 10) == 0
        else
          false
        end

      _ ->
        false
    end
  end

  def valid_routing_number?(_), do: false

  defp validate_routing_numbers(%AchFile{batches: batches}) do
    batches
    |> Enum.flat_map(fn %Batch{entries: entries} -> entries end)
    |> Enum.flat_map(fn {%EntryDetail{} = entry, _addenda} ->
      rdfi_with_check = entry.receiving_dfi_identification <> entry.check_digit

      if valid_routing_number?(rdfi_with_check) do
        []
      else
        ["Invalid ABA check digit for routing number #{rdfi_with_check}"]
      end
    end)
  end

  defp validate_transaction_codes(%AchFile{batches: batches}) do
    batches
    |> Enum.flat_map(fn %Batch{entries: entries} -> entries end)
    |> Enum.flat_map(fn {%EntryDetail{} = entry, _addenda} ->
      validate_transaction_code(entry)
    end)
  end

  defp validate_transaction_code(%EntryDetail{
         transaction_code: code,
         amount: amount,
         trace_number: trace
       }) do
    cond do
      not TransactionCode.valid?(code) ->
        ["Unknown transaction code #{inspect(code)} on entry #{trace}"]

      TransactionCode.prenote?(code) and amount != 0 ->
        [
          "Prenotification entry #{trace} (transaction code #{code}) must have amount 0, got #{amount}"
        ]

      true ->
        []
    end
  end

  defp validate_addenda_codes(%AchFile{batches: batches}) do
    batches
    |> Enum.flat_map(fn %Batch{entries: entries} -> entries end)
    |> Enum.flat_map(fn {_entry, addenda} -> Enum.flat_map(addenda, &validate_addenda_code/1) end)
  end

  defp validate_addenda_code(%Addenda99{
         return_reason_code: code,
         original_entry_trace_number: trace
       }) do
    if ReturnReasonCode.valid?(code) do
      []
    else
      ["Unknown return reason code #{inspect(code)} on Addenda99 for trace #{trace}"]
    end
  end

  defp validate_addenda_code(%Addenda98{
         change_code: code,
         original_entry_trace_number: trace
       }) do
    if ChangeCode.valid?(code) do
      []
    else
      ["Unknown change code #{inspect(code)} on Addenda98 for trace #{trace}"]
    end
  end

  defp validate_addenda_code(_other), do: []

  defp validate_batch_trailers(%AchFile{batches: batches}) do
    Enum.flat_map(batches, &validate_batch_trailer/1)
  end

  defp validate_batch_trailer(%Batch{entries: entries, trailer: trailer}) do
    expected_count = count_entries_and_addenda(entries)
    expected_hash = entry_hash(entries)
    {expected_debit, expected_credit} = sum_amounts(entries)

    []
    |> append_if(
      trailer.entry_addenda_count != expected_count,
      "Batch trailer entry/addenda count #{trailer.entry_addenda_count} does not match actual #{expected_count}"
    )
    |> append_if(
      normalize_hash(trailer.entry_hash) != expected_hash,
      "Batch trailer entry hash #{trailer.entry_hash} does not match actual #{pad_hash(expected_hash)}"
    )
    |> append_if(
      trailer.total_debit != expected_debit,
      "Batch trailer total debit #{trailer.total_debit} does not match actual #{expected_debit}"
    )
    |> append_if(
      trailer.total_credit != expected_credit,
      "Batch trailer total credit #{trailer.total_credit} does not match actual #{expected_credit}"
    )
  end

  defp validate_file_control(%AchFile{batches: batches, control: control} = file) do
    expected_batch_count = length(batches)

    expected_entry_addenda =
      batches
      |> Enum.map(fn %Batch{entries: entries} -> count_entries_and_addenda(entries) end)
      |> Enum.sum()

    expected_entry_hash =
      batches
      |> Enum.map(fn %Batch{entries: entries} -> entry_hash(entries) end)
      |> Enum.sum()
      |> rem(@hash_modulus)

    {expected_debit, expected_credit} =
      batches
      |> Enum.map(fn %Batch{entries: entries} -> sum_amounts(entries) end)
      |> Enum.reduce({0, 0}, fn {d, c}, {td, tc} -> {td + d, tc + c} end)

    expected_block_count = block_count(file)

    []
    |> append_if(
      control.batch_count != expected_batch_count,
      "File control batch count #{control.batch_count} does not match actual #{expected_batch_count}"
    )
    |> append_if(
      control.entry_addenda_count != expected_entry_addenda,
      "File control entry/addenda count #{control.entry_addenda_count} does not match actual #{expected_entry_addenda}"
    )
    |> append_if(
      normalize_hash(control.entry_hash) != expected_entry_hash,
      "File control entry hash #{control.entry_hash} does not match actual #{pad_hash(expected_entry_hash)}"
    )
    |> append_if(
      control.total_debit != expected_debit,
      "File control total debit #{control.total_debit} does not match actual #{expected_debit}"
    )
    |> append_if(
      control.total_credit != expected_credit,
      "File control total credit #{control.total_credit} does not match actual #{expected_credit}"
    )
    |> append_if(
      control.block_count != expected_block_count,
      "File control block count #{control.block_count} does not match actual #{expected_block_count}"
    )
  end

  defp count_entries_and_addenda(entries) do
    Enum.reduce(entries, 0, fn {_entry, addenda}, acc -> acc + 1 + length(addenda) end)
  end

  defp entry_hash(entries) do
    entries
    |> Enum.map(fn {%EntryDetail{} = entry, _} ->
      entry.receiving_dfi_identification |> String.to_integer()
    end)
    |> Enum.sum()
    |> rem(@hash_modulus)
  end

  defp sum_amounts(entries) do
    Enum.reduce(entries, {0, 0}, fn {%EntryDetail{} = entry, _addenda}, {debit, credit} ->
      case TransactionCode.direction(entry.transaction_code) do
        :credit -> {debit, credit + entry.amount}
        :debit -> {debit + entry.amount, credit}
        nil -> {debit, credit}
      end
    end)
  end

  defp block_count(%AchFile{batches: batches}) do
    record_total =
      1 + 1 +
        Enum.reduce(batches, 0, fn %Batch{entries: entries}, acc ->
          acc + 2 + count_entries_and_addenda(entries)
        end)

    div(record_total + 9, 10)
  end

  defp normalize_hash(hash) when is_binary(hash), do: String.to_integer(hash)
  defp normalize_hash(hash) when is_integer(hash), do: hash

  defp pad_hash(hash), do: hash |> Integer.to_string() |> String.pad_leading(10, "0")

  defp append_if(list, true, msg), do: list ++ [msg]
  defp append_if(list, false, _msg), do: list
end
