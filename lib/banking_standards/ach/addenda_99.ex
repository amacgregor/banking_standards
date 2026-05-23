defmodule BankingStandards.ACH.Addenda99 do
  @moduledoc """
  Addenda record, type code 99 — return entry (Record Type 7).

  Companion to a return entry. Carries the return reason code (R-code) and the
  trace number of the original entry being returned.
  """

  defstruct [
    :record_type_code,
    :addenda_type_code,
    :return_reason_code,
    :original_entry_trace_number,
    :date_of_death,
    :original_receiving_dfi_identification,
    :addenda_information,
    :trace_number
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          addenda_type_code: String.t(),
          return_reason_code: String.t(),
          original_entry_trace_number: String.t(),
          date_of_death: String.t(),
          original_receiving_dfi_identification: String.t(),
          addenda_information: String.t(),
          trace_number: String.t()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{record_type_code: "7", addenda_type_code: "99"}), do: :ok
  def validate(%__MODULE__{}), do: {:error, "Invalid record_type_code or addenda_type_code"}
end
