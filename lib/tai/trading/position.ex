defmodule Tai.Trading.Position do
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type t :: %Tai.Trading.Position{
          venue_id: atom,
          account_id: atom,
          product_symbol: product_symbol,
          cost: Decimal.t(),
          qty: Decimal.t()
        }

  @enforce_keys [
    :venue_id,
    :account_id,
    :product_symbol,
    :cost,
    :qty
  ]
  defstruct [
    :venue_id,
    :account_id,
    :product_symbol,
    :cost,
    :qty
  ]
end
