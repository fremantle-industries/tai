defmodule Tai.ExchangeAdapters.Gdax.Serializers.L2Update do
  def normalize(changes) do
    changes
    |> Enum.reduce(%{bids: %{}, asks: %{}}, &add_changed_price_level/2)
  end

  defp add_changed_price_level([side, price, size], acc) do
    {parsed_price, _} = Float.parse(price)
    {parsed_size, _} = Float.parse(size)
    nside = side |> normalize_side
    price_levels = acc[nside] |> Map.put(parsed_price, {parsed_size, nil, nil})

    acc
    |> Map.put(nside, price_levels)
  end

  defp normalize_side("buy"), do: :bids
  defp normalize_side("sell"), do: :asks
end
