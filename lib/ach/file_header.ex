defmodule BankingStandards.ACH.FileHeader do
  @moduledoc """
  Represents the file header record in an ACH file (Record Type Code 1).
  """

  defstruct [
    :record_type_code,
    :priority_code,
    :immediate_destination,
    :immediate_origin,
    :file_creation_date,
    :file_creation_time,
    :file_id_modifier,
    :record_size,
    :blocking_factor,
    :format_code,
    :immediate_destination_name,
    :immediate_origin_name
  ]

  @type t :: %__MODULE__{
          record_type_code: String.t(),
          priority_code: String.t(),
          immediate_destination: String.t(),
          immediate_origin: String.t(),
          file_creation_date: String.t(),
          file_creation_time: String.t(),
          file_id_modifier: String.t(),
          record_size: String.t(),
          blocking_factor: String.t(),
          format_code: String.t(),
          immediate_destination_name: String.t(),
          immediate_origin_name: String.t()
        }

  @spec validate(t()) :: :ok | {:error, String.t()}
  def validate(%__MODULE__{} = header) do
    errors = []

    # Validate required fields
    errors =
      if header.record_type_code != "1" do
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
