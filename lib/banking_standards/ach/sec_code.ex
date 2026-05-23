defmodule BankingStandards.ACH.SecCode do
  @moduledoc """
  Standard Entry Class (SEC) codes that classify NACHA batches and constrain
  what transaction codes and addenda records they may contain.

  This module covers the 10 domestic SEC codes — `PPD`, `CCD`, `CIE`, `CTX`,
  `WEB`, `TEL`, `ARC`, `BOC`, `POP`, `RCK`. International ACH (`IAT`) is
  intentionally absent here because it carries a mandatory addenda chain
  (types 10–18) with its own validation rules; that lands in PR 3c.

  Each SEC has a spec:

  - `transaction_codes` — which `EntryDetail.transaction_code` values are permitted.
  - `addenda` — `{min, max, allowed_type_codes}` constraining how many and which kind of addenda an entry may carry. Addenda types `98` (NOC) and `99` (return) are not modelled here because they appear on return/NOC files, not on original-entry files.

  The spec is intentionally conservative: a code listed here is one that
  NACHA explicitly permits for the SEC. Stricter per-SEC rules (e.g. WEB's
  payment-type indicator in `discretionary_data`, POP's terminal location
  format) are out of scope for this PR.
  """

  alias BankingStandards.ACH.TransactionCode

  @specs %{
    "PPD" => %{
      name: "Prearranged Payment and Deposit",
      account_holder_type: :consumer,
      transaction_codes: ~w(22 23 24 27 28 29 32 33 34 37 38 39),
      addenda: {0, 1, ["05"]}
    },
    "CCD" => %{
      name: "Corporate Credit or Debit",
      account_holder_type: :business,
      transaction_codes: ~w(22 23 24 27 28 29 32 33 34 37 38 39),
      addenda: {0, 1, ["05"]}
    },
    "CIE" => %{
      name: "Customer-Initiated Entry",
      account_holder_type: :consumer,
      transaction_codes: ~w(22 23 24 32 33 34),
      addenda: {0, 9999, ["05"]}
    },
    "CTX" => %{
      name: "Corporate Trade Exchange",
      account_holder_type: :business,
      transaction_codes: ~w(22 23 24 27 28 29 32 33 34 37 38 39),
      addenda: {0, 9999, ["05"]}
    },
    "WEB" => %{
      name: "Internet-Initiated Entry",
      account_holder_type: :consumer,
      transaction_codes: ~w(22 23 24 27 28 29 32 33 34 37 38 39),
      addenda: {0, 1, ["05"]}
    },
    "TEL" => %{
      name: "Telephone-Initiated Entry",
      account_holder_type: :consumer,
      transaction_codes: ~w(27 28 29 37 38 39),
      addenda: {0, 1, ["05"]}
    },
    "ARC" => %{
      name: "Accounts Receivable Conversion",
      account_holder_type: :consumer,
      transaction_codes: ~w(27 28 29 37 38 39),
      addenda: {0, 0, []}
    },
    "BOC" => %{
      name: "Back Office Conversion",
      account_holder_type: :consumer,
      transaction_codes: ~w(27 28 29 37 38 39),
      addenda: {0, 0, []}
    },
    "POP" => %{
      name: "Point-of-Purchase",
      account_holder_type: :consumer,
      transaction_codes: ~w(27 37),
      addenda: {0, 0, []}
    },
    "RCK" => %{
      name: "Re-presented Check",
      account_holder_type: :consumer,
      transaction_codes: ~w(27 37),
      addenda: {0, 0, []}
    }
  }

  @type spec :: %{
          name: String.t(),
          account_holder_type: :consumer | :business,
          transaction_codes: [String.t()],
          addenda: {non_neg_integer(), non_neg_integer(), [String.t()]}
        }

  @doc "All known SEC codes."
  @spec all() :: [String.t()]
  def all, do: Map.keys(@specs)

  @doc "Whether `code` is a known domestic NACHA SEC code modelled by this module."
  @spec valid?(String.t() | nil) :: boolean()
  def valid?(code), do: Map.has_key?(@specs, code)

  @doc "Full spec for a SEC code, or `nil` if unknown."
  @spec spec(String.t()) :: spec() | nil
  def spec(code), do: Map.get(@specs, code)

  @doc "Permitted transaction codes for `sec_code`, or `nil` if unknown."
  @spec allowed_transaction_codes(String.t()) :: [String.t()] | nil
  def allowed_transaction_codes(code) do
    case spec(code) do
      %{transaction_codes: codes} -> codes
      nil -> nil
    end
  end

  @doc "Permitted `{min, max}` addenda count for `sec_code`, or `nil` if unknown."
  @spec addenda_range(String.t()) :: {non_neg_integer(), non_neg_integer()} | nil
  def addenda_range(code) do
    case spec(code) do
      %{addenda: {min, max, _types}} -> {min, max}
      nil -> nil
    end
  end

  @doc "Permitted addenda type codes for `sec_code`, or `nil` if unknown."
  @spec allowed_addenda_types(String.t()) :: [String.t()] | nil
  def allowed_addenda_types(code) do
    case spec(code) do
      %{addenda: {_min, _max, types}} -> types
      nil -> nil
    end
  end

  @doc """
  Checks that every entry of every known SEC permits at least one
  transaction code from `TransactionCode.all/0`. Used as a registry
  sanity check in tests.
  """
  @spec all_transaction_codes_known?() :: boolean()
  def all_transaction_codes_known? do
    known = MapSet.new(TransactionCode.all())

    Enum.all?(@specs, fn {_sec, %{transaction_codes: codes}} ->
      Enum.all?(codes, &MapSet.member?(known, &1))
    end)
  end
end
