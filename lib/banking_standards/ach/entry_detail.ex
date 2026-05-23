defmodule BankingStandards.ACH.EntryDetail do
  @moduledoc """
  Represents an entry detail in an ACH file (Record Type Code 6).
  """

  defstruct [
    :record_type_code,
    :transaction_code,
    :receiving_dfi_identification,
    :check_digit,
    :dfi_account_number,
    :amount,
    :individual_identification_number,
    :individual_name,
    :discretionary_data,
    :addenda_record_indicator,
    :trace_number
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          transaction_code: String.t(),
          receiving_dfi_identification: String.t(),
          check_digit: String.t(),
          dfi_account_number: String.t(),
          amount: integer(),
          individual_identification_number: String.t(),
          individual_name: String.t(),
          discretionary_data: String.t(),
          addenda_record_indicator: integer(),
          trace_number: String.t()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = entry) do
    errors = []

    # Validate record_type_code
    errors =
      if entry.record_type_code != "6" do
        ["Invalid record_type_code" | errors]
      else
        errors
      end

    # Validate transaction_code
    errors =
      if entry.transaction_code == nil do
        ["transaction_code is required" | errors]
      else
        errors
      end

    # Validate receiving_dfi_identification
    errors =
      if entry.receiving_dfi_identification == nil do
        ["receiving_dfi_identification is required" | errors]
      else
        errors
      end

    # Validate amount
    errors =
      if entry.amount == nil or entry.amount < 0 do
        ["amount must be a positive integer" | errors]
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
