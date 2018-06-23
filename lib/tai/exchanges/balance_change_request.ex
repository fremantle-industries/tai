defmodule Tai.Exchanges.BalanceChangeRequest do
  @type t :: %Tai.Exchanges.BalanceChangeRequest{asset: atom, amount: Decimal.t()}

  @enforce_keys [:asset, :amount]
  defstruct [:asset, :amount]

  @spec new(atom, Decimal.t()) :: t
  def new(asset, amount) do
    %Tai.Exchanges.BalanceChangeRequest{
      asset: asset,
      amount: Decimal.new(amount)
    }
  end
end
