defmodule Tai.VenueAdapters.Binance.Stream.DepthUpdate do
  @moduledoc """
  Normalize the data received from a depthUpdate event
  """

  def normalize(raw_price_levels, received_at, venue_sent_at) do
    raw_price_levels
    |> Enum.reduce(
      %{},
      fn [raw_price, raw_size], acc ->
        {price, _} = Float.parse(raw_price)
        {size, _} = Float.parse(raw_size)
        Map.put(acc, price, {size, received_at, venue_sent_at})
      end
    )
  end
end
