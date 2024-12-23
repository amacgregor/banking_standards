defmodule BankingStandards.ACH.BatchTrailer do
  @moduledoc """
  Represents a batch trailer in an ACH file (Record Type Code 8).
  """

  defstruct [
    :record_type_code,
    :service_class_code,
    :entry_addenda_count,
    :entry_hash,
    :total_debit,
    :total_credit,
    :company_identification,
    :originating_dfi_identification,
    :batch_number
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          service_class_code: String.t(),
          entry_addenda_count: integer(),
          entry_hash: String.t(),
          total_debit: integer(),
          total_credit: integer(),
          company_identification: String.t(),
          originating_dfi_identification: String.t(),
          batch_number: String.t()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = trailer) do
    errors = []

    # Validate record_type_code
    errors =
      if trailer.record_type_code != "8" do
        ["Invalid record_type_code" | errors]
      else
        errors
      end

    # Validate total_debit
    errors =
      if trailer.total_debit == nil do
        ["total_debit is required" | errors]
      else
        errors
      end

    # Validate total_credit
    errors =
      if trailer.total_credit == nil do
        ["total_credit is required" | errors]
      else
        errors
      end

    # Join and return errors
    case Enum.reverse(errors) do
      [] -> :ok
      reversed_errors -> {:error, Enum.join(reversed_errors, ", ")}
    end
  end
end
