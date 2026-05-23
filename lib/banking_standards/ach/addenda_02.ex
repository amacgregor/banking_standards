defmodule BankingStandards.ACH.Addenda02 do
  @moduledoc """
  Addenda record, type code 02 — point-of-sale / shared network terminal info
  (Record Type 7). Used with MTE, POS, SHR entries.
  """

  defstruct [
    :record_type_code,
    :addenda_type_code,
    :reference_information_1,
    :reference_information_2,
    :terminal_identification_code,
    :transaction_serial_number,
    :transaction_date,
    :authorization_code_or_card_expiration_date,
    :terminal_location,
    :terminal_city,
    :terminal_state,
    :trace_number
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          addenda_type_code: String.t(),
          reference_information_1: String.t(),
          reference_information_2: String.t(),
          terminal_identification_code: String.t(),
          transaction_serial_number: String.t(),
          transaction_date: String.t(),
          authorization_code_or_card_expiration_date: String.t(),
          terminal_location: String.t(),
          terminal_city: String.t(),
          terminal_state: String.t(),
          trace_number: String.t()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{record_type_code: "7", addenda_type_code: "02"}), do: :ok
  def validate(%__MODULE__{}), do: {:error, "Invalid record_type_code or addenda_type_code"}
end
