defmodule Examples.LogTrade.Events.Trade do
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
    liquidation
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

defimpl TaiEvents.LogEvent, for: Examples.LogTrade.Events.Trade do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:price, event.price && event.price |> Decimal.to_string(:normal))
    |> Map.put(:qty, event.qty && event.qty |> Decimal.to_string(:normal))
  end
end
