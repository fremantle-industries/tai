defmodule Tai.Exchanges.AssetBalance do
  @type t :: %Tai.Exchanges.AssetBalance{
          exchange_id: atom,
          account_id: atom,
          asset: atom,
          free: Decimal.t(),
          locked: Decimal.t()
        }

  @enforce_keys [
    :exchange_id,
    :account_id,
    :asset,
    :free,
    :locked
  ]
  defstruct [
    :exchange_id,
    :account_id,
    :asset,
    :free,
    :locked
  ]

  @spec new(
          exchange_id :: atom,
          account_id :: atom,
          asset :: atom,
          free :: number | String.t() | Decimal.t(),
          locked :: number | String.t() | Decimal.t()
        ) :: t
  def new(exchange_id, account_id, asset, free, locked) do
    %Tai.Exchanges.AssetBalance{
      exchange_id: exchange_id,
      account_id: account_id,
      asset: asset,
      free: Decimal.new(free),
      locked: Decimal.new(locked)
    }
  end

  @spec total(balance :: t) :: Decimal.t()
  def total(%Tai.Exchanges.AssetBalance{free: free, locked: locked}) do
    Decimal.add(free, locked)
  end
end
