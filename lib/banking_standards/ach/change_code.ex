defmodule BankingStandards.ACH.ChangeCode do
  @moduledoc """
  NACHA Notification of Change (NOC) codes. These appear in
  `Addenda98.change_code` and indicate what receiver information the ODFI
  should update for future entries.
  """

  @codes %{
    "C01" => "Incorrect DFI Account Number",
    "C02" => "Incorrect Routing Number",
    "C03" => "Incorrect Routing Number and Account Number",
    "C04" => "Incorrect Individual Name / Receiving Company Name",
    "C05" => "Incorrect Transaction Code",
    "C06" => "Incorrect Account Number and Transaction Code",
    "C07" => "Incorrect Routing Number, Account Number, and Transaction Code",
    "C08" => "Incorrect Receiving DFI Identification (IAT Only)",
    "C09" => "Incorrect Individual Identification Number",
    "C10" => "Incorrect Company Name",
    "C11" => "Incorrect Company Identification",
    "C12" => "Incorrect Company Name and Company Identification",
    "C13" => "Addenda Format Error",
    "C14" => "Incorrect SEC Code for Outbound IAT"
  }

  @doc "All known NOC change codes."
  @spec all() :: [String.t()]
  def all, do: Map.keys(@codes)

  @doc "Whether `code` is a known NACHA Notification of Change code."
  @spec valid?(String.t() | nil) :: boolean()
  def valid?(code), do: Map.has_key?(@codes, code)

  @doc "Returns the human-readable description for a known code, or `nil`."
  @spec description(String.t()) :: String.t() | nil
  def description(code), do: Map.get(@codes, code)
end
