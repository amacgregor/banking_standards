defmodule BankingStandards.ACH.FileControl do
  @moduledoc """
  Represents the file control record in an ACH file (Record Type Code 9).
  """

  defstruct [
    :record_type_code,
    :batch_count,
    :block_count,
    :entry_addenda_count,
    :entry_hash,
    :total_debit,
    :total_credit
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          batch_count: integer(),
          block_count: integer(),
          entry_addenda_count: integer(),
          entry_hash: String.t(),
          total_debit: integer(),
          total_credit: integer()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = control) do
    errors = []

    # Validate record_type_code
    errors =
      if control.record_type_code != "9" do
        ["Invalid record_type_code" | errors]
      else
        errors
      end

    case errors do
      [] -> :ok
      _ -> {:error, Enum.join(errors, ", ")}
    end
  end
end
