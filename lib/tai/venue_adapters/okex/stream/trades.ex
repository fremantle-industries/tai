defmodule Tai.VenueAdapters.OkEx.Stream.Trades do
  alias Tai.Events

  def broadcast(
        %{
          "instrument_id" => venue_symbol,
          "price" => price,
          "qty" => qty,
          "side" => side,
          "timestamp" => timestamp
        },
        venue_id,
        received_at
      ) do
    Events.info(%Events.Trade{
      venue_id: venue_id,
      # TODO: 
      # The list of products or a map of exchange symbol to symbol should be 
      # passed in. This currently doesn't support _ within the symbol
      symbol: venue_symbol |> String.downcase() |> String.to_atom(),
      received_at: received_at,
      timestamp: timestamp,
      price: price,
      qty: qty,
      side: side |> normalize_side
    })
  end

  defp normalize_side("buy"), do: :buy
  defp normalize_side("sell"), do: :sell
end
