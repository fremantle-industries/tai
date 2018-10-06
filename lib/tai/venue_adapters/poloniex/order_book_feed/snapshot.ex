defmodule Tai.VenueAdapters.Poloniex.OrderBookFeed.Snapshot do
  def normalize(%{} = price_and_sizes, processed_at) do
    price_and_sizes
    |> Enum.reduce(%{}, fn {price_str, size_str}, acc ->
      {price, _} = Float.parse(price_str)
      {size, _} = Float.parse(size_str)

      acc
      |> Map.put(price, {size, processed_at, nil})
    end)
  end
end
