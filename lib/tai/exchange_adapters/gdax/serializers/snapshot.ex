defmodule Tai.ExchangeAdapters.Gdax.Serializers.Snapshot do
  def normalize(snapshot_side, processed_at) do
    snapshot_side
    |> Enum.reduce(%{}, fn [price, size], acc ->
      {parsed_price, _} = Float.parse(price)
      {parsed_size, _} = Float.parse(size)

      acc
      |> Map.put(parsed_price, {parsed_size, processed_at, nil})
    end)
  end
end
