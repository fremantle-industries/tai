defmodule Tai.VenueAdapters.OkEx.Stream.Trades do
  alias Tai.Events
  import Tai.VenueAdapters.OkEx.Products, only: [to_symbol: 1]

  def broadcast(
        %{
          "instrument_id" => instrument_id,
          "price" => price,
          "qty" => qty,
          "side" => side,
          "timestamp" => timestamp,
          "trade_id" => venue_trade_id
        },
        venue_id,
        received_at
      ) do
    Events.info(%Events.Trade{
      venue_id: venue_id,
      symbol: instrument_id |> to_symbol,
      received_at: received_at,
      timestamp: timestamp,
      price: price |> Decimal.cast(),
      qty: qty |> Decimal.cast(),
      side: side |> normalize_side,
      venue_trade_id: venue_trade_id
    })
  end

  def broadcast(
        %{
          "instrument_id" => instrument_id,
          "price" => price,
          "size" => size,
          "side" => side,
          "timestamp" => timestamp,
          "trade_id" => venue_trade_id
        },
        venue_id,
        received_at
      ) do
    Events.info(%Events.Trade{
      venue_id: venue_id,
      symbol: instrument_id |> to_symbol,
      received_at: received_at,
      timestamp: timestamp,
      price: price |> Decimal.cast(),
      qty: size |> Decimal.cast(),
      side: side |> normalize_side,
      venue_trade_id: venue_trade_id
    })
  end

  defp normalize_side("buy"), do: :buy
  defp normalize_side("sell"), do: :sell
end
