defmodule Tai.Exchanges.AssetBalanceChangeRequest do
  @type t :: %Tai.Exchanges.AssetBalanceChangeRequest{asset: atom, amount: Decimal.t()}

  @enforce_keys [:asset, :amount]
  defstruct [:asset, :amount]

  @spec new(atom, Decimal.t()) :: t
  def new(asset, amount) do
    %Tai.Exchanges.AssetBalanceChangeRequest{
      asset: asset,
      amount: Decimal.new(amount)
    }
  end
end
