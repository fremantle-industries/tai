defmodule Tai.Venues.FeeInfo do
  @type fee_type :: :percent
  @type t :: %Tai.Venues.FeeInfo{
          venue_id: Tai.Venue.id(),
          account_id: Tai.Venue.account_id(),
          symbol: Tai.Venues.Product.symbol(),
          maker: Decimal.t(),
          maker_type: fee_type,
          taker: Decimal.t(),
          taker_type: fee_type
        }

  @enforce_keys ~w(
    venue_id
    account_id
    symbol
    maker
    maker_type
    taker
    taker_type
  )a
  defstruct ~w(
    venue_id
    account_id
    symbol
    maker
    maker_type
    taker
    taker_type
  )a

  def percent, do: :percent
end
