defmodule Tai.Markets.Trade do
  @moduledoc """
  Represents a normalized trade on a venue
  """

  @type t :: %__MODULE__{
    id: String.t() | integer,
    liquidation: boolean,
    price: Decimal.t(),
    product_symbol: atom,
    qty: Decimal.t(),
    received_at: integer,
    side: String.t(),
    venue: atom,
    venue_timestamp: DateTime.t() | nil
  }

  @enforce_keys ~w[
    id
    price
    product_symbol
    qty
    received_at
    side
    venue
    venue_timestamp
  ]a
  defstruct ~w[
    id
    liquidation
    price
    product_symbol
    qty
    received_at
    side
    venue
    venue_timestamp
  ]a
end
