defmodule BankingStandards.ACH.Batch do
  @moduledoc """
  A batch within an ACH file: header, entries with their addenda, and trailer.
  """

  alias BankingStandards.ACH.{
    Addenda02,
    Addenda05,
    Addenda98,
    Addenda99,
    BatchHeader,
    BatchTrailer,
    EntryDetail
  }

  defstruct [:header, :entries, :trailer]

  @type addenda :: Addenda02.t() | Addenda05.t() | Addenda98.t() | Addenda99.t()
  @type entry_with_addenda :: {EntryDetail.t(), [addenda()]}

  @type t :: %__MODULE__{
          header: BatchHeader.t(),
          entries: [entry_with_addenda()],
          trailer: BatchTrailer.t()
        }
end
