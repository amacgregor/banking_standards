defmodule BankingStandards.ACH.BatchHeader do
  @moduledoc """
  Represents a batch header in an ACH file (Record Type Code 5).
  """

  defstruct [
    :record_type_code,
    :service_class_code,
    :company_name,
    :company_discretionary_data,
    :company_identification,
    :standard_entry_class_code,
    :company_entry_description,
    :company_descriptive_date,
    :effective_entry_date,
    :settlement_date,
    :originator_status_code,
    :originating_dfi_identification,
    :batch_number
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          service_class_code: String.t(),
          company_name: String.t(),
          company_discretionary_data: String.t(),
          company_identification: String.t(),
          standard_entry_class_code: String.t(),
          company_entry_description: String.t(),
          company_descriptive_date: String.t(),
          effective_entry_date: String.t(),
          settlement_date: String.t(),
          originator_status_code: String.t(),
          originating_dfi_identification: String.t(),
          batch_number: String.t()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = header) do
    errors = []

    errors =
      if header.record_type_code != "5" do
        ["Invalid record_type_code" | errors]
      else
        errors
      end

    errors =
      if header.company_name == nil do
        ["company_name is required" | errors]
      else
        errors
      end

    errors =
      if header.company_identification == nil do
        ["company_identification is required" | errors]
      else
        errors
      end

    # Join the errors
    case Enum.reverse(errors) do
      [] -> :ok
      reversed_errors -> {:error, Enum.join(reversed_errors, ", ")}
    end
  end

end
