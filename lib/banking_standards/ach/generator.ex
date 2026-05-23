defmodule BankingStandards.ACH.Generator do
  @moduledoc """
  Serializes an `AchFile` back into the 94-character fixed-width NACHA format.

  Each record is formatted to exactly 94 characters, joined with newlines.
  The resulting file is padded with `9`-fill records so the total record
  count is a multiple of 10 (the NACHA blocking factor).

  Trailer and control values are written verbatim from the struct — the
  Generator does **not** recompute them. Use `Validator.validate/1` first
  if the values may be inconsistent.
  """

  alias BankingStandards.ACH.{
    AchFile,
    Addenda02,
    Addenda05,
    Addenda98,
    Addenda99,
    Batch,
    BatchHeader,
    BatchTrailer,
    EntryDetail,
    FileControl,
    FileHeader
  }

  @block_size 10
  @record_length 94
  @padding_record String.duplicate("9", @record_length)

  @spec generate(AchFile.t()) :: String.t()
  def generate(%AchFile{} = file) do
    file
    |> records()
    |> pad_to_block()
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  @spec write(AchFile.t(), Path.t()) :: :ok | {:error, File.posix()}
  def write(%AchFile{} = file, path) do
    File.write(path, generate(file))
  end

  defp records(%AchFile{header: header, batches: batches, control: control}) do
    [format_file_header(header)] ++
      Enum.flat_map(batches, &format_batch/1) ++
      [format_file_control(control)]
  end

  defp format_batch(%Batch{header: header, entries: entries, trailer: trailer}) do
    [format_batch_header(header)] ++
      Enum.flat_map(entries, fn {entry, addenda} ->
        [format_entry_detail(entry) | Enum.map(addenda, &format_addenda/1)]
      end) ++
      [format_batch_trailer(trailer)]
  end

  defp pad_to_block(records) do
    case rem(length(records), @block_size) do
      0 -> records
      n -> records ++ List.duplicate(@padding_record, @block_size - n)
    end
  end

  defp format_file_header(%FileHeader{} = h) do
    fixed_length(
      "1" <>
        alpha(h.priority_code, 2) <>
        leading_space(h.immediate_destination, 10) <>
        leading_space(h.immediate_origin, 10) <>
        alpha(h.file_creation_date, 6) <>
        alpha(h.file_creation_time, 4) <>
        alpha(h.file_id_modifier, 1) <>
        alpha(h.record_size, 3) <>
        alpha(h.blocking_factor, 2) <>
        alpha(h.format_code, 1) <>
        alpha(h.immediate_destination_name, 23) <>
        alpha(h.immediate_origin_name, 23) <>
        blank(8)
    )
  end

  defp format_batch_header(%BatchHeader{} = h) do
    fixed_length(
      "5" <>
        alpha(h.service_class_code, 3) <>
        alpha(h.company_name, 16) <>
        alpha(h.company_discretionary_data, 20) <>
        alpha(h.company_identification, 10) <>
        alpha(h.standard_entry_class_code, 3) <>
        alpha(h.company_entry_description, 10) <>
        alpha(h.company_descriptive_date, 6) <>
        alpha(h.effective_entry_date, 6) <>
        alpha(h.settlement_date, 3) <>
        alpha(h.originator_status_code, 1) <>
        alpha(h.originating_dfi_identification, 8) <>
        alpha(h.batch_number, 7)
    )
  end

  defp format_entry_detail(%EntryDetail{} = e) do
    fixed_length(
      "6" <>
        alpha(e.transaction_code, 2) <>
        alpha(e.receiving_dfi_identification, 8) <>
        alpha(e.check_digit, 1) <>
        alpha(e.dfi_account_number, 17) <>
        numeric(e.amount, 10) <>
        alpha(e.individual_identification_number, 15) <>
        alpha(e.individual_name, 22) <>
        alpha(e.discretionary_data, 2) <>
        numeric(e.addenda_record_indicator, 1) <>
        alpha(e.trace_number, 15)
    )
  end

  defp format_addenda(%Addenda05{} = a) do
    fixed_length(
      "7" <>
        alpha(a.addenda_type_code, 2) <>
        alpha(a.payment_related_information, 80) <>
        numeric(a.addenda_sequence_number, 4) <>
        numeric(a.entry_detail_sequence_number, 7)
    )
  end

  defp format_addenda(%Addenda02{} = a) do
    fixed_length(
      "7" <>
        alpha(a.addenda_type_code, 2) <>
        alpha(a.reference_information_1, 7) <>
        alpha(a.reference_information_2, 3) <>
        alpha(a.terminal_identification_code, 6) <>
        alpha(a.transaction_serial_number, 6) <>
        alpha(a.transaction_date, 4) <>
        alpha(a.authorization_code_or_card_expiration_date, 6) <>
        alpha(a.terminal_location, 27) <>
        alpha(a.terminal_city, 15) <>
        alpha(a.terminal_state, 2) <>
        alpha(a.trace_number, 15)
    )
  end

  defp format_addenda(%Addenda98{} = a) do
    fixed_length(
      "7" <>
        alpha(a.addenda_type_code, 2) <>
        alpha(a.change_code, 3) <>
        alpha(a.original_entry_trace_number, 15) <>
        blank(6) <>
        alpha(a.corrected_data, 29) <>
        blank(23) <>
        alpha(a.original_receiving_dfi_identification, 8) <>
        alpha(a.trace_number, 7)
    )
  end

  defp format_addenda(%Addenda99{} = a) do
    fixed_length(
      "7" <>
        alpha(a.addenda_type_code, 2) <>
        alpha(a.return_reason_code, 3) <>
        alpha(a.original_entry_trace_number, 15) <>
        alpha(a.date_of_death, 6) <>
        alpha(a.original_receiving_dfi_identification, 8) <>
        alpha(a.addenda_information, 44) <>
        alpha(a.trace_number, 15)
    )
  end

  defp format_batch_trailer(%BatchTrailer{} = t) do
    fixed_length(
      "8" <>
        alpha(t.service_class_code, 3) <>
        numeric(t.entry_addenda_count, 6) <>
        alpha(t.entry_hash, 10) <>
        numeric(t.total_debit, 12) <>
        numeric(t.total_credit, 12) <>
        alpha(t.company_identification, 10) <>
        blank(19) <>
        blank(6) <>
        alpha(t.originating_dfi_identification, 8) <>
        alpha(t.batch_number, 7)
    )
  end

  defp format_file_control(%FileControl{} = c) do
    fixed_length(
      "9" <>
        numeric(c.batch_count, 6) <>
        numeric(c.block_count, 6) <>
        numeric(c.entry_addenda_count, 8) <>
        alpha(c.entry_hash, 10) <>
        numeric(c.total_debit, 12) <>
        numeric(c.total_credit, 12) <>
        blank(39)
    )
  end

  defp alpha(nil, length), do: blank(length)

  defp alpha(value, length) when is_binary(value) do
    value |> String.pad_trailing(length) |> String.slice(0, length)
  end

  defp leading_space(nil, length), do: blank(length)

  defp leading_space(value, length) when is_binary(value) do
    value |> String.pad_leading(length) |> String.slice(-length, length)
  end

  defp numeric(nil, length), do: String.duplicate("0", length)

  defp numeric(value, length) when is_integer(value) do
    value
    |> Integer.to_string()
    |> String.pad_leading(length, "0")
    |> String.slice(-length, length)
  end

  defp blank(length), do: String.duplicate(" ", length)

  defp fixed_length(record) when byte_size(record) == @record_length, do: record

  defp fixed_length(record) do
    raise "Record is #{byte_size(record)} bytes, expected #{@record_length}: #{inspect(record)}"
  end
end
