defmodule Tai.ExchangeAdapters.Mock.Snapshot do
  def normalize(snapshot_side, processed_at) do
    snapshot_side
    |> Enum.reduce(
      %{},
      fn {price_str, size}, acc ->
        with {price, ""} <- Float.parse(price_str) do
          Map.put(acc, price, {size, processed_at, nil})
        end
      end
    )
  end
end
