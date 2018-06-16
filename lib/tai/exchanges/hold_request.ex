defmodule Tai.Exchanges.HoldRequest do
  @type t :: %Tai.Exchanges.HoldRequest{account_id: atom, asset: atom, amount: Decimal.t()}

  @enforce_keys [:account_id, :asset, :amount]
  defstruct [:account_id, :asset, :amount]

  @spec new(atom, atom, Decimal.t()) :: t
  def new(account_id, asset, amount) do
    %Tai.Exchanges.HoldRequest{
      account_id: account_id,
      asset: asset,
      amount: Decimal.new(amount)
    }
  end
end
