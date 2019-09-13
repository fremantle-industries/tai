defmodule Tai.VenueAdapters.Gdax.OrderBookFeed.L2Update do
  @type order_book :: Tai.Markets.OrderBook.t()
  @type change :: [...]

  @spec normalize(atom, atom, [[change]], DateTime.t(), DateTime.t()) :: order_book
  def normalize(venue_id, symbol, changes, received_at, venue_timestamp) do
    changes
    |> Enum.reduce(
      %Tai.Markets.OrderBook{
        venue_id: venue_id,
        product_symbol: symbol,
        bids: %{},
        asks: %{},
        last_received_at: received_at,
        last_venue_timestamp: venue_timestamp
      },
      fn [side, price, size], acc ->
        {parsed_price, _} = Float.parse(price)
        {parsed_size, _} = Float.parse(size)
        nside = side |> normalize_side

        new_price_levels =
          acc
          |> Map.get(nside)
          |> Map.put(parsed_price, {parsed_size, received_at, venue_timestamp})

        acc
        |> Map.put(nside, new_price_levels)
      end
    )
  end

  defp normalize_side("buy"), do: :bids
  defp normalize_side("sell"), do: :asks
end
