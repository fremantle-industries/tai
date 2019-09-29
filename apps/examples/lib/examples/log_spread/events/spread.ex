defmodule Examples.LogSpread.Events.Spread do
  alias __MODULE__

  @type t :: %Spread{
          venue_id: atom,
          product_symbol: atom,
          bid_price: Decimal.t(),
          bid_size: Decimal.t(),
          ask_price: Decimal.t(),
          ask_size: Decimal.t(),
          spread: Decimal.t()
        }

  @enforce_keys ~w(
    venue_id
    product_symbol
    bid_price
    bid_size
    ask_price
    ask_size
    spread
  )a
  defstruct ~w(
    venue_id
    product_symbol
    bid_price
    bid_size
    ask_price
    ask_size
    spread
  )a
end

defimpl Tai.LogEvent, for: Examples.LogSpread.Events.Spread do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(:bid_price, event.bid_price && event.bid_price |> Decimal.to_string(:normal))
    |> Map.put(:bid_size, event.bid_size && event.bid_size |> Decimal.to_string(:normal))
    |> Map.put(:ask_price, event.ask_price && event.ask_price |> Decimal.to_string(:normal))
    |> Map.put(:ask_size, event.ask_size && event.ask_size |> Decimal.to_string(:normal))
    |> Map.put(:spread, event.spread && event.spread |> Decimal.to_string(:normal))
  end
end
