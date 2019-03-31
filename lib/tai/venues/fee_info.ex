defmodule Tai.Venues.FeeInfo do
  @type fee_type :: :percent
  @type t :: %Tai.Venues.FeeInfo{
          exchange_id: atom,
          account_id: atom,
          symbol: atom,
          maker: Decimal.t(),
          maker_type: fee_type,
          taker: Decimal.t(),
          taker_type: fee_type
        }

  @enforce_keys ~w(
    exchange_id
    account_id
    symbol
    maker
    maker_type
    taker
    taker_type
  )a
  defstruct ~w(
    exchange_id
    account_id
    symbol
    maker
    maker_type
    taker
    taker_type
  )a

  def percent, do: :percent
end
