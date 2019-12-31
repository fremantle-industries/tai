defmodule Tai.Venues.FeeInfo do
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type symbol :: Tai.Venues.Product.symbol()
  @type fee_type :: :percent
  @type t :: %Tai.Venues.FeeInfo{
          venue_id: venue_id,
          credential_id: credential_id,
          symbol: symbol,
          maker: Decimal.t(),
          maker_type: fee_type,
          taker: Decimal.t(),
          taker_type: fee_type
        }

  @enforce_keys ~w(
    venue_id
    credential_id
    symbol
    maker
    maker_type
    taker
    taker_type
  )a
  defstruct ~w(
    venue_id
    credential_id
    symbol
    maker
    maker_type
    taker
    taker_type
  )a

  def percent, do: :percent
end
