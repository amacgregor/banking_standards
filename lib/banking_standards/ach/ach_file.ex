defmodule BankingStandards.ACH.AchFile do
  @moduledoc """
  A parsed NACHA ACH file: file header, batches, and file control record.

  Block padding (record type 9999...) is consumed by the parser and not
  represented in this struct — the generator re-pads on write.
  """

  alias BankingStandards.ACH.{Batch, FileControl, FileHeader}

  defstruct [:header, :batches, :control]

  @type t :: %__MODULE__{
          header: FileHeader.t(),
          batches: [Batch.t()],
          control: FileControl.t()
        }
end
