defmodule BankingStandards.ACH.ReturnReasonCode do
  @moduledoc """
  NACHA return reason codes (R-codes). These appear in `Addenda99.return_reason_code`
  and explain why an entry was returned by the RDFI.

  Covers the standard consumer/corporate codes (R01–R29), network-level codes
  (R30–R39), ENR and RCK codes (R40–R57), and IAT/dishonored-return codes
  (R61–R85). Some codes are SEC-specific (e.g., R80–R85 are IAT-only) but
  this module only checks code membership — per-SEC applicability lives in
  the SEC code modules in PR 3b.
  """

  @codes %{
    "R01" => "Insufficient Funds",
    "R02" => "Account Closed",
    "R03" => "No Account/Unable to Locate Account",
    "R04" => "Invalid Account Number Structure",
    "R05" => "Unauthorized Debit to Consumer Account Using Corporate SEC Code",
    "R06" => "Returned per ODFI's Request",
    "R07" => "Authorization Revoked by Customer",
    "R08" => "Payment Stopped",
    "R09" => "Uncollected Funds",
    "R10" => "Customer Advises Originator is Not Known to Receiver and/or Not Authorized",
    "R11" => "Customer Advises Entry Not in Accordance with Terms of Authorization",
    "R12" => "Account Sold to Another DFI",
    "R13" => "Invalid ACH Routing Number",
    "R14" => "Representative Payee Deceased or Unable to Continue in That Capacity",
    "R15" => "Beneficiary or Account Holder Deceased",
    "R16" => "Account Frozen/Entry Returned per OFAC Instruction",
    "R17" => "File Record Edit Criteria/Entry with Invalid Account Number",
    "R18" => "Improper Effective Entry Date",
    "R19" => "Amount Field Error",
    "R20" => "Non-Transaction Account",
    "R21" => "Invalid Company Identification",
    "R22" => "Invalid Individual ID Number",
    "R23" => "Credit Entry Refused by Receiver",
    "R24" => "Duplicate Entry",
    "R25" => "Addenda Error",
    "R26" => "Mandatory Field Error",
    "R27" => "Trace Number Error",
    "R28" => "Routing Number Check Digit Error",
    "R29" => "Corporate Customer Advises Not Authorized",
    "R30" => "RDFI Not Participant in Check Truncation Program",
    "R31" => "Permissible Return Entry (CCD and CTX only)",
    "R32" => "RDFI Non-Settlement",
    "R33" => "Return of XCK Entry",
    "R34" => "Limited Participation DFI",
    "R35" => "Return of Improper Debit Entry",
    "R36" => "Return of Improper Credit Entry",
    "R37" => "Source Document Presented for Payment",
    "R38" => "Stop Payment on Source Document",
    "R39" => "Improper Source Document/Source Document Presented for Payment",
    "R40" => "Return of ENR Entry by Federal Government Agency (ENR Only)",
    "R41" => "Invalid Transaction Code (ENR Only)",
    "R42" => "Routing Number/Check Digit Error (ENR Only)",
    "R43" => "Invalid DFI Account Number (ENR Only)",
    "R44" => "Invalid Individual ID Number (ENR Only)",
    "R45" => "Invalid Individual Name/Company Name (ENR Only)",
    "R46" => "Invalid Representative Payee Indicator (ENR Only)",
    "R47" => "Duplicate Enrollment (ENR Only)",
    "R50" => "State Law Affecting RCK Acceptance",
    "R51" => "Item Related to RCK Entry is Ineligible or RCK Entry is Improper",
    "R52" => "Stop Payment on Item Related to RCK Entry",
    "R53" => "Item and RCK Entry Presented for Payment",
    "R61" => "Misrouted Return",
    "R62" => "Return of Erroneous or Reversing Debit",
    "R67" => "Duplicate Return",
    "R68" => "Untimely Return",
    "R69" => "Field Error(s)",
    "R70" => "Permissible Return Entry Not Accepted/Return Not Requested by ODFI",
    "R71" => "Misrouted Dishonored Return",
    "R72" => "Untimely Dishonored Return",
    "R73" => "Timely Original Return",
    "R74" => "Corrected Return",
    "R75" => "Return Not a Duplicate",
    "R76" => "No Errors Found",
    "R77" => "Non-Acceptance of R62 Dishonored Return",
    "R80" => "IAT Entry Coding Error (IAT Only)",
    "R81" => "Non-Participant in IAT Program (IAT Only)",
    "R82" => "Invalid Foreign Receiving DFI Identification (IAT Only)",
    "R83" => "Foreign Receiving DFI Unable to Settle (IAT Only)",
    "R84" => "Entry Not Processed by Gateway (IAT Only)",
    "R85" => "Incorrectly Coded Outbound International Payment (IAT Only)"
  }

  @doc "All known return reason codes."
  @spec all() :: [String.t()]
  def all, do: Map.keys(@codes)

  @doc "Whether `code` is a known NACHA return reason code."
  @spec valid?(String.t() | nil) :: boolean()
  def valid?(code), do: Map.has_key?(@codes, code)

  @doc "Returns the human-readable description for a known code, or `nil`."
  @spec description(String.t()) :: String.t() | nil
  def description(code), do: Map.get(@codes, code)
end
