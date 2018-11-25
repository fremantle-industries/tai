defmodule Tai.VenueAdapters.Bitmex.Stream.Settlements do
  def broadcast(
        %{
          "settledPrice" => price,
          "symbol" => exchange_symbol,
          "timestamp" => timestamp
        },
        venue_id,
        received_at
      ) do
    Tai.Events.broadcast(%Tai.Events.Settlement{
      venue_id: venue_id,
      # TODO: The list of products or a map of exchange symbol to symbol should be passed in
      symbol: exchange_symbol |> normalize_symbol,
      timestamp: timestamp,
      received_at: received_at,
      price: price
    })
  end

  defp normalize_symbol(exchange_symbol) do
    exchange_symbol
    |> String.downcase()
    |> String.to_atom()
  end
end
