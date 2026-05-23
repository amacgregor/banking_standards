defmodule BankingStandards.ACH.TransactionCode do
  @moduledoc """
  NACHA transaction codes. Each code packs three pieces of information into
  two digits: the direction (credit/debit), the receiving account type
  (checking, savings, general ledger, loan), and the kind of entry (live
  payment, prenotification, or zero-dollar/remittance).

  Codes are exposed as binaries (`"22"`, `"27"`, …) since that is how they
  appear on the wire in an `EntryDetail` record.
  """

  @type direction :: :credit | :debit
  @type account_type :: :checking | :savings | :general_ledger | :loan
  @type kind :: :live | :prenote | :zero_dollar

  # {code, direction, account_type, kind}
  @codes [
    {"22", :credit, :checking, :live},
    {"23", :credit, :checking, :prenote},
    {"24", :credit, :checking, :zero_dollar},
    {"27", :debit, :checking, :live},
    {"28", :debit, :checking, :prenote},
    {"29", :debit, :checking, :zero_dollar},
    {"32", :credit, :savings, :live},
    {"33", :credit, :savings, :prenote},
    {"34", :credit, :savings, :zero_dollar},
    {"37", :debit, :savings, :live},
    {"38", :debit, :savings, :prenote},
    {"39", :debit, :savings, :zero_dollar},
    {"42", :credit, :general_ledger, :live},
    {"43", :credit, :general_ledger, :prenote},
    {"44", :credit, :general_ledger, :zero_dollar},
    {"47", :debit, :general_ledger, :live},
    {"48", :debit, :general_ledger, :prenote},
    {"49", :debit, :general_ledger, :zero_dollar},
    {"52", :credit, :loan, :live},
    {"53", :credit, :loan, :prenote},
    {"54", :credit, :loan, :zero_dollar},
    {"55", :debit, :loan, :live}
  ]

  @lookup Map.new(@codes, fn {code, dir, acct, kind} -> {code, {dir, acct, kind}} end)

  @doc "All known transaction codes."
  @spec all() :: [String.t()]
  def all, do: Enum.map(@codes, fn {code, _, _, _} -> code end)

  @doc "Whether `code` is a known NACHA transaction code."
  @spec valid?(String.t() | nil) :: boolean()
  def valid?(code), do: Map.has_key?(@lookup, code)

  @doc "Returns `:credit` or `:debit` for a known code, `nil` otherwise."
  @spec direction(String.t()) :: direction() | nil
  def direction(code), do: with({d, _, _} <- Map.get(@lookup, code), do: d)

  @doc """
  Returns the receiving account type (`:checking`, `:savings`,
  `:general_ledger`, `:loan`) for a known code, `nil` otherwise.
  """
  @spec account_type(String.t()) :: account_type() | nil
  def account_type(code), do: with({_, a, _} <- Map.get(@lookup, code), do: a)

  @doc "Returns `:live`, `:prenote`, or `:zero_dollar` for a known code, `nil` otherwise."
  @spec kind(String.t()) :: kind() | nil
  def kind(code), do: with({_, _, k} <- Map.get(@lookup, code), do: k)

  @doc "Whether the code is a prenotification (zero-amount test entry)."
  @spec prenote?(String.t()) :: boolean()
  def prenote?(code), do: kind(code) == :prenote

  @doc "Whether the code is credit-side."
  @spec credit?(String.t()) :: boolean()
  def credit?(code), do: direction(code) == :credit

  @doc "Whether the code is debit-side."
  @spec debit?(String.t()) :: boolean()
  def debit?(code), do: direction(code) == :debit
end
