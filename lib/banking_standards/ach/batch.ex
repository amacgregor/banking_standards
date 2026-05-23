defmodule BankingStandards.ACH.Batch do
  @moduledoc """
  A batch within an ACH file: header, entries with their addenda, and trailer.
  """

  alias BankingStandards.ACH.{AddendaRecord, BatchHeader, BatchTrailer, EntryDetail}

  defstruct [:header, :entries, :trailer]

  @type entry_with_addenda :: {EntryDetail.t(), [AddendaRecord.t()]}

  @type t :: %__MODULE__{
          header: BatchHeader.t(),
          entries: [entry_with_addenda()],
          trailer: BatchTrailer.t()
        }
end
