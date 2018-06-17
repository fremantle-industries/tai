defmodule Tai.Exchanges.LockRequest do
  @type t :: %Tai.Exchanges.LockRequest{asset: atom, amount: Decimal.t()}

  @enforce_keys [:asset, :amount]
  defstruct [:asset, :amount]

  @spec new(atom, Decimal.t()) :: t
  def new(asset, amount) do
    %Tai.Exchanges.LockRequest{
      asset: asset,
      amount: Decimal.new(amount)
    }
  end
end
