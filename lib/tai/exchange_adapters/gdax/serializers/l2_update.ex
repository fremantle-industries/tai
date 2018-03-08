defmodule Tai.ExchangeAdapters.Gdax.Serializers.L2Update do
  def normalize(changes, processed_at, server_changed_at) do
    changes
    |> Enum.reduce(
      %{bids: %{}, asks: %{}},
      fn [side, price, size], acc ->
        {parsed_price, _} = Float.parse(price)
        {parsed_size, _} = Float.parse(size)
        nside = side |> normalize_side
        new_price_levels = acc[nside] |> Map.put(parsed_price, {parsed_size, processed_at, server_changed_at})

        acc
        |> Map.put(nside, new_price_levels)
      end
    )
  end

  defp normalize_side("buy"), do: :bids
  defp normalize_side("sell"), do: :asks
end
