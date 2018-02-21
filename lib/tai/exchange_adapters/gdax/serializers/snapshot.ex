defmodule Tai.ExchangeAdapters.Gdax.Serializers.Snapshot do
  def normalize(snapshot_side) do
    []
    |> normalize(snapshot_side)
  end

  defp normalize(acc, []), do: acc
  defp normalize(acc, [[price, size] | tail]) do
    {parsed_price, _} = Float.parse(price)
    {parsed_size, _} = Float.parse(size)

    [{parsed_price, parsed_size} | acc]
    |> normalize(tail)
  end
end
