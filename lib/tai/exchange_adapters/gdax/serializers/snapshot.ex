defmodule Tai.ExchangeAdapters.Gdax.Serializers.Snapshot do
  def normalize(snapshot_side) do
    snapshot_side
    |> Enum.reduce(%{}, &add_snapshot_price_level/2)
  end

  defp add_snapshot_price_level([price, size], acc) do
    {parsed_price, _} = Float.parse(price)
    {parsed_size, _} = Float.parse(size)

    acc
    |> Map.put(parsed_price, {parsed_size, nil, nil})
  end
end
