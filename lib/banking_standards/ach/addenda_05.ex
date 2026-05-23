defmodule BankingStandards.ACH.Addenda05 do
  @moduledoc """
  Addenda record, type code 05 — payment-related information (Record Type 7).

  Used with CCD, CTX, PPD, WEB, TEL, and most other SEC codes to carry free-form
  payment-related information for the preceding entry detail.
  """

  defstruct [
    :record_type_code,
    :addenda_type_code,
    :payment_related_information,
    :addenda_sequence_number,
    :entry_detail_sequence_number
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          addenda_type_code: String.t(),
          payment_related_information: String.t(),
          addenda_sequence_number: integer(),
          entry_detail_sequence_number: integer()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{record_type_code: "7", addenda_type_code: "05"}), do: :ok
  def validate(%__MODULE__{}), do: {:error, "Invalid record_type_code or addenda_type_code"}
end
