defmodule Tai.VenueAdapters.Gdax.OrderBookFeed.L2Update do
  @type order_book :: Tai.Markets.OrderBook.t()
  @type change :: [...]

  @spec normalize(atom, atom, [[change]], DateTime.t(), DateTime.t()) :: order_book
  def normalize(venue_id, symbol, changes, processed_at, server_changed_at) do
    changes
    |> Enum.reduce(
      %Tai.Markets.OrderBook{
        venue_id: venue_id,
        product_symbol: symbol,
        bids: %{},
        asks: %{}
      },
      fn [side, price, size], acc ->
        {parsed_price, _} = Float.parse(price)
        {parsed_size, _} = Float.parse(size)
        nside = side |> normalize_side

        new_price_levels =
          acc
          |> Map.get(nside)
          |> Map.put(parsed_price, {parsed_size, processed_at, server_changed_at})

        acc
        |> Map.put(nside, new_price_levels)
      end
    )
  end

  defp normalize_side("buy"), do: :bids
  defp normalize_side("sell"), do: :asks
end
