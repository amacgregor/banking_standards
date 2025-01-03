defmodule BankingStandards.ACH.AddendaRecord do
  @moduledoc """
  Represents an addenda record in an ACH file (Record Type Code 7XX).
  """

  defstruct [
    :record_type_code,
    :addenda_type_code,
    :trace_number,
    :payment_related_information,
    :addenda_sequence_number,
    :entry_detail_sequence_number
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          addenda_type_code: String.t(),
          trace_number: String.t(),
          payment_related_information: String.t(),
          addenda_sequence_number: integer(),
          entry_detail_sequence_number: integer()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = addenda) do
    errors = []

    errors =
      if addenda.record_type_code != "7" do
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
