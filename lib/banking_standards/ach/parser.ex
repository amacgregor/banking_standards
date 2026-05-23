defmodule BankingStandards.ACH.Parser do
  @moduledoc """
  Parses NACHA ACH files into a hierarchical `AchFile` struct.

  Parsing is two-pass: each 94-character line is tokenized into a typed
  record, then a state machine assembles the records into
  `AchFile -> [Batch -> [{EntryDetail, [AddendaRecord]}]]`. Files with
  records out of sequence (e.g. an entry after a batch trailer with no
  new batch header) are rejected with `{:error, reason}`.
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

  @line_length 95

  @spec parse(String.t()) :: {:ok, AchFile.t()} | {:error, String.t()}
  def parse(file_path) do
    file_path
    |> File.stream!()
    |> tokenize()
    |> case do
      {:ok, records} -> assemble(records)
      {:error, _} = error -> error
    end
  end

  defp tokenize(line_stream) do
    line_stream
    |> Stream.with_index(1)
    |> Enum.reduce_while({:ok, []}, fn {line, index}, {:ok, acc} ->
      case parse_line(line, index) do
        {:ok, :padding} -> {:cont, {:ok, acc}}
        {:ok, record} -> {:cont, {:ok, [record | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      error -> error
    end
  end

  defp parse_line(line, index) do
    if String.length(line) != @line_length do
      {:error, "Line length error on line #{index}"}
    else
      dispatch_record(line, index)
    end
  end

  defp dispatch_record(line, index) do
    case String.slice(line, 0, 3) do
      "101" -> {:ok, parse_file_header(line)}
      "5" <> _ -> {:ok, parse_batch_header(line)}
      "6" <> _ -> {:ok, parse_entry_detail(line)}
      "7" <> _ -> parse_addenda(line, index)
      "8" <> _ -> {:ok, parse_batch_trailer(line)}
      "900" -> {:ok, parse_file_control(line)}
      "999" -> {:ok, :padding}
      _ -> {:error, "Invalid record type '#{String.slice(line, 0, 3)}' on line #{index}"}
    end
  end

  defp assemble(records) do
    records
    |> Enum.reduce_while({:ok, :awaiting_file_header, nil}, fn record, {:ok, state, acc} ->
      case step(state, acc, record) do
        {:ok, new_state, new_acc} -> {:cont, {:ok, new_state, new_acc}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, :done, ach_file} -> {:ok, ach_file}
      {:ok, state, _} -> {:error, "Unexpected end of file in state #{inspect(state)}"}
      error -> error
    end
  end

  defp step(:awaiting_file_header, nil, %FileHeader{} = header) do
    {:ok, :in_file, %{header: header, batches: [], current_batch: nil}}
  end

  defp step(:awaiting_file_header, _, record) do
    {:error, "Expected file header, got #{record_label(record)}"}
  end

  defp step(:in_file, acc, %BatchHeader{} = batch_header) do
    {:ok, :in_batch, %{acc | current_batch: %{header: batch_header, entries: []}}}
  end

  defp step(:in_file, acc, %FileControl{} = control) do
    ach_file = %AchFile{
      header: acc.header,
      batches: Enum.reverse(acc.batches),
      control: control
    }

    {:ok, :done, ach_file}
  end

  defp step(:in_file, _, record) do
    {:error, "Expected batch header or file control, got #{record_label(record)}"}
  end

  defp step(:in_batch, acc, %EntryDetail{} = entry) do
    batch = %{acc.current_batch | entries: [{entry, []} | acc.current_batch.entries]}
    {:ok, :in_batch, %{acc | current_batch: batch}}
  end

  defp step(
         :in_batch,
         %{current_batch: %{entries: [{entry, addenda} | rest]}} = acc,
         addenda_record
       )
       when is_struct(addenda_record, Addenda02) or is_struct(addenda_record, Addenda05) or
              is_struct(addenda_record, Addenda98) or is_struct(addenda_record, Addenda99) do
    batch = %{acc.current_batch | entries: [{entry, [addenda_record | addenda]} | rest]}
    {:ok, :in_batch, %{acc | current_batch: batch}}
  end

  defp step(:in_batch, %{current_batch: %{entries: []}}, addenda_record)
       when is_struct(addenda_record, Addenda02) or is_struct(addenda_record, Addenda05) or
              is_struct(addenda_record, Addenda98) or is_struct(addenda_record, Addenda99) do
    {:error, "Addenda record before any entry detail in batch"}
  end

  defp step(:in_batch, acc, %BatchTrailer{} = trailer) do
    entries =
      acc.current_batch.entries
      |> Enum.reverse()
      |> Enum.map(fn {entry, addenda} -> {entry, Enum.reverse(addenda)} end)

    batch = %Batch{
      header: acc.current_batch.header,
      entries: entries,
      trailer: trailer
    }

    {:ok, :in_file, %{acc | batches: [batch | acc.batches], current_batch: nil}}
  end

  defp step(:in_batch, _, record) do
    {:error, "Expected entry detail, addenda, or batch trailer, got #{record_label(record)}"}
  end

  defp step(:done, _, record) do
    {:error, "Unexpected record after file control: #{record_label(record)}"}
  end

  defp record_label(%FileHeader{}), do: "file header"
  defp record_label(%BatchHeader{}), do: "batch header"
  defp record_label(%EntryDetail{}), do: "entry detail"
  defp record_label(%Addenda02{}), do: "addenda record"
  defp record_label(%Addenda05{}), do: "addenda record"
  defp record_label(%Addenda98{}), do: "addenda record"
  defp record_label(%Addenda99{}), do: "addenda record"
  defp record_label(%BatchTrailer{}), do: "batch trailer"
  defp record_label(%FileControl{}), do: "file control"

  defp parse_file_header(line) do
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
  end

  defp parse_batch_header(line) do
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
  end

  defp parse_entry_detail(line) do
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
  end

  defp parse_addenda(line, index) do
    case String.slice(line, 1, 2) do
      "02" -> {:ok, parse_addenda_02(line)}
      "05" -> {:ok, parse_addenda_05(line)}
      "98" -> {:ok, parse_addenda_98(line)}
      "99" -> {:ok, parse_addenda_99(line)}
      type -> {:error, "Unsupported addenda type code '#{type}' on line #{index}"}
    end
  end

  defp parse_addenda_02(line) do
    %Addenda02{
      record_type_code: String.slice(line, 0, 1),
      addenda_type_code: String.slice(line, 1, 2),
      reference_information_1: String.slice(line, 3, 7) |> String.trim(),
      reference_information_2: String.slice(line, 10, 3) |> String.trim(),
      terminal_identification_code: String.slice(line, 13, 6) |> String.trim(),
      transaction_serial_number: String.slice(line, 19, 6) |> String.trim(),
      transaction_date: String.slice(line, 25, 4) |> String.trim(),
      authorization_code_or_card_expiration_date: String.slice(line, 29, 6) |> String.trim(),
      terminal_location: String.slice(line, 35, 27) |> String.trim(),
      terminal_city: String.slice(line, 62, 15) |> String.trim(),
      terminal_state: String.slice(line, 77, 2) |> String.trim(),
      trace_number: String.slice(line, 79, 15) |> String.trim()
    }
  end

  defp parse_addenda_05(line) do
    %Addenda05{
      record_type_code: String.slice(line, 0, 1),
      addenda_type_code: String.slice(line, 1, 2),
      payment_related_information: String.slice(line, 3, 80) |> String.trim(),
      addenda_sequence_number: String.slice(line, 83, 4) |> String.trim() |> String.to_integer(),
      entry_detail_sequence_number:
        String.slice(line, 87, 7) |> String.trim() |> String.to_integer()
    }
  end

  defp parse_addenda_98(line) do
    %Addenda98{
      record_type_code: String.slice(line, 0, 1),
      addenda_type_code: String.slice(line, 1, 2),
      change_code: String.slice(line, 3, 3) |> String.trim(),
      original_entry_trace_number: String.slice(line, 6, 15) |> String.trim(),
      original_receiving_dfi_identification: String.slice(line, 79, 8) |> String.trim(),
      corrected_data: String.slice(line, 27, 29) |> String.trim(),
      trace_number: String.slice(line, 87, 7) |> String.trim()
    }
  end

  defp parse_addenda_99(line) do
    %Addenda99{
      record_type_code: String.slice(line, 0, 1),
      addenda_type_code: String.slice(line, 1, 2),
      return_reason_code: String.slice(line, 3, 3) |> String.trim(),
      original_entry_trace_number: String.slice(line, 6, 15) |> String.trim(),
      date_of_death: String.slice(line, 21, 6) |> String.trim(),
      original_receiving_dfi_identification: String.slice(line, 27, 8) |> String.trim(),
      addenda_information: String.slice(line, 35, 44) |> String.trim(),
      trace_number: String.slice(line, 79, 15) |> String.trim()
    }
  end

  defp parse_batch_trailer(line) do
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
  end

  defp parse_file_control(line) do
    %FileControl{
      record_type_code: String.slice(line, 0, 1),
      batch_count: String.slice(line, 1, 6) |> String.trim() |> String.to_integer(),
      block_count: String.slice(line, 7, 6) |> String.trim() |> String.to_integer(),
      entry_addenda_count: String.slice(line, 13, 8) |> String.trim() |> String.to_integer(),
      entry_hash: String.slice(line, 21, 10) |> String.trim(),
      total_debit: String.slice(line, 31, 12) |> String.trim() |> String.to_integer(),
      total_credit: String.slice(line, 43, 12) |> String.trim() |> String.to_integer()
    }
  end
end
