defmodule Tai.VenueAdapters.Gdax.OrderBookFeed.Snapshot do
  def normalize(snapshot_side) do
    snapshot_side
    |> Enum.reduce(%{}, fn [price, size], acc ->
      {parsed_price, _} = Float.parse(price)
      {parsed_size, _} = Float.parse(size)
      Map.put(acc, parsed_price, parsed_size)
    end)
  end
end
