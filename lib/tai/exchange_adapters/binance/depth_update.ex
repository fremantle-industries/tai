defmodule Tai.ExchangeAdapters.Binance.DepthUpdate do
  @moduledoc """
  Normalize the data received from a depthUpdate event
  """

  @doc """
  Convert the list of price & sizes to a map of price levels
  """
  def normalize(raw_price_levels, processed_at, server_changed_at) do
    raw_price_levels
    |> Enum.reduce(%{}, fn [price_str, size_str, _], acc ->
      {price, _} = Float.parse(price_str)
      {size, _} = Float.parse(size_str)

      Map.put(acc, price, {size, processed_at, server_changed_at})
    end)
  end
end
