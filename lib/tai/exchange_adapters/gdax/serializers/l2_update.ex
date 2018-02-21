defmodule Tai.ExchangeAdapters.Gdax.Serializers.L2Update do
  def normalize(changes) do
    []
    |> normalize(changes)
  end

  defp normalize(acc, []), do: acc
  defp normalize(acc, [[side, price, size] | tail]) do
    {parsed_price, _} = Float.parse(price)
    {parsed_size, _} = Float.parse(size)

    [[side: side |> normalize_side, price: parsed_price, size: parsed_size] | acc]
    |> normalize(tail)
  end

  defp normalize_side("buy"), do: :bid
  defp normalize_side("sell"), do: :ask
end
