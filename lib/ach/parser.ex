defmodule BankingStandards.ACH.Parser do
  @moduledoc """
  Parses ACH files in NACHA format and maps them to validated structs.
  """

  alias BankingStandards.ACH.{BatchHeader, EntryDetail, BatchTrailer, FileHeader, AddendaRecord}

  @spec parse(String.t()) :: {:ok, [BatchHeader.t() | EntryDetail.t() | BatchTrailer.t()]} | {:error, String.t()}
  def parse(file_path) do
    File.stream!(file_path)
    |> Stream.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {line, index}, {:ok, acc} ->
      case parse_line(line, index) do
        {:ok, nil} -> {:cont, {:ok, acc}} # Skip padding
        {:ok, struct} -> {:cont, {:ok, [struct | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, result} -> {:ok, Enum.reverse(result)}
      error -> error
    end
  end

  @spec parse_line(String.t(), integer()) ::
          {:ok, BatchHeader.t() | EntryDetail.t() | BatchTrailer.t()} | {:error, String.t()}
  defp parse_line(line, index) do

    # Validate line length
    if String.length(line) != 95 do
      {:error, "Line length error on line #{index}"}
    else
      case String.slice(line, 0, 3) do
        "101" -> parse_file_header(line, index)
        "5" <> _ -> parse_batch_header(line, index)
        "6" <> _ -> parse_entry_detail(line, index)
        "7" <> _ -> parse_addenda_record(line, index)
        "8" <> _ -> parse_batch_trailer(line, index)
        "900" -> parse_file_control(line, index)
        "999" -> {:ok, nil}
        _ -> {:error, "Invalid record type '#{String.slice(line, 0, 3)}' on line #{index}"}
      end
    end
  end

  defp parse_addenda_record(line, _index) do
    %BankingStandards.ACH.AddendaRecord{
      record_type_code: String.slice(line, 0, 1),
      addenda_type_code: String.slice(line, 1, 2),
      payment_related_information: String.slice(line, 3, 80) |> String.trim(),
      addenda_sequence_number: String.slice(line, 83, 4) |> String.trim() |> String.to_integer(),
      entry_detail_sequence_number: String.slice(line, 87, 7) |> String.trim() |> String.to_integer()
    }
    |> validate_struct(BankingStandards.ACH.AddendaRecord)
  end


  defp parse_file_header(line, _index) do
    %FileHeader{
      record_type_code: String.slice(line, 0, 1),
      priority_code: String.slice(line, 1, 2),
      immediate_destination: String.slice(line, 3, 10) |> String.trim(),
      immediate_origin: String.slice(line, 13, 10) |> String.trim(),
      file_creation_date: String.slice(line, 23, 6),
      file_creation_time: String.slice(line, 29, 4),
      file_id_modifier: String.slice(line, 33, 1),
      record_size: String.slice(line, 34, 3),
      blocking_factor: String.slice(line, 37, 2),
      format_code: String.slice(line, 39, 1),
      immediate_destination_name: String.slice(line, 40, 23) |> String.trim(),
      immediate_origin_name: String.slice(line, 63, 23) |> String.trim()
    }
    |> validate_struct(FileHeader)
  end

  defp parse_file_control(line, _index) do
    %BankingStandards.ACH.FileControl{
      record_type_code: String.slice(line, 0, 1),
      batch_count: String.slice(line, 1, 6) |> String.trim() |> String.to_integer(),
      block_count: String.slice(line, 7, 6) |> String.trim() |> String.to_integer(),
      entry_addenda_count: String.slice(line, 13, 8) |> String.trim() |> String.to_integer(),
      entry_hash: String.slice(line, 21, 10) |> String.trim(),
      total_debit: String.slice(line, 31, 12) |> String.trim() |> String.to_integer(),
      total_credit: String.slice(line, 43, 12) |> String.trim() |> String.to_integer()
    }
    |> validate_struct(BankingStandards.ACH.FileControl)
  end

  defp parse_batch_header(line, _index) do
    %BatchHeader{
      record_type_code: String.slice(line, 0, 1),
      service_class_code: String.slice(line, 1, 3) |> String.trim(),
      company_name: String.slice(line, 4, 16) |> String.trim(),
      company_discretionary_data: String.slice(line, 20, 20) |> String.trim(),
      company_identification: String.slice(line, 40, 10) |> String.trim(),
      standard_entry_class_code: String.slice(line, 50, 3) |> String.trim(),
      company_entry_description: String.slice(line, 53, 10) |> String.trim(),
      company_descriptive_date: String.slice(line, 63, 6) |> String.trim(),
      effective_entry_date: String.slice(line, 69, 6) |> String.trim(),
      settlement_date: String.slice(line, 75, 3) |> String.trim(),
      originator_status_code: String.slice(line, 78, 1) |> String.trim(),
      originating_dfi_identification: String.slice(line, 79, 8) |> String.trim(),
      batch_number: String.slice(line, 87, 7) |> String.trim()
    }
    |> validate_struct(BatchHeader)
  end


  defp parse_entry_detail(line, _index) do
    %EntryDetail{
      record_type_code: String.slice(line, 0, 1),
      transaction_code: String.slice(line, 1, 2) |> String.trim(),
      receiving_dfi_identification: String.slice(line, 3, 8) |> String.trim(),
      check_digit: String.slice(line, 11, 1) |> String.trim(),
      dfi_account_number: String.slice(line, 12, 17) |> String.trim(),
      amount: String.slice(line, 29, 10) |> String.trim() |> String.to_integer(),
      individual_identification_number: String.slice(line, 39, 15) |> String.trim(),
      individual_name: String.slice(line, 54, 22) |> String.trim(),
      discretionary_data: String.slice(line, 76, 2) |> String.trim(),
      addenda_record_indicator: String.slice(line, 78, 1) |> String.trim() |> String.to_integer(),
      trace_number: String.slice(line, 79, 15) |> String.trim()
    }
    |> validate_struct(EntryDetail)
  end


  defp parse_batch_trailer(line, _index) do
    %BatchTrailer{
      record_type_code: String.slice(line, 0, 1),
      service_class_code: String.slice(line, 1, 3) |> String.trim(),
      entry_addenda_count: String.slice(line, 4, 6) |> String.trim() |> String.to_integer(),
      entry_hash: String.slice(line, 10, 10) |> String.trim(),
      total_debit: String.slice(line, 20, 12) |> String.trim() |> String.to_integer(),
      total_credit: String.slice(line, 32, 12) |> String.trim() |> String.to_integer(),
      company_identification: String.slice(line, 44, 10) |> String.trim(),
      originating_dfi_identification: String.slice(line, 54, 8) |> String.trim(),
      batch_number: String.slice(line, 62, 7) |> String.trim()
    }
    |> validate_struct(BatchTrailer)
  end


  defp validate_struct(struct, module) do
    case module.validate(struct) do
      :ok -> {:ok, struct}
      {:error, error} -> {:error, error}
    end
  end
end
