defmodule BankingStandards.ACH.Addenda98 do
  @moduledoc """
  Addenda record, type code 98 — Notification of Change (Record Type 7).

  Companion to a COR (Notification of Change) return entry. Tells the originator
  that account information needs to be corrected for future entries.
  """

  defstruct [
    :record_type_code,
    :addenda_type_code,
    :change_code,
    :original_entry_trace_number,
    :original_receiving_dfi_identification,
    :corrected_data,
    :trace_number
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          addenda_type_code: String.t(),
          change_code: String.t(),
          original_entry_trace_number: String.t(),
          original_receiving_dfi_identification: String.t(),
          corrected_data: String.t(),
          trace_number: String.t()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{record_type_code: "7", addenda_type_code: "98"}), do: :ok
  def validate(%__MODULE__{}), do: {:error, "Invalid record_type_code or addenda_type_code"}
end
