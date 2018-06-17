defmodule Tai.Exchanges.HoldRequest do
  @type t :: %Tai.Exchanges.HoldRequest{asset: atom, amount: Decimal.t()}

  @enforce_keys [:asset, :amount]
  defstruct [:asset, :amount]

  @spec new(atom, Decimal.t()) :: t
  def new(asset, amount) do
    %Tai.Exchanges.HoldRequest{
      asset: asset,
      amount: Decimal.new(amount)
    }
  end
end
