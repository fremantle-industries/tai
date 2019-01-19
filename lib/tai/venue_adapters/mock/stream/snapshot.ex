defmodule Tai.VenueAdapters.Mock.Stream.Snapshot do
  def normalize(snapshot_side, processed_at) do
    snapshot_side
    |> Enum.reduce(
      %{},
      &add_change_point(&1, processed_at, &2)
    )
  end

  defp add_change_point(
         {price_str, %{"size" => size, "server_changed_at" => changed_str}},
         processed_at,
         acc
       ) do
    {price, ""} = Float.parse(price_str)
    {:ok, server_changed_at, 0} = DateTime.from_iso8601(changed_str)
    Map.put(acc, price, {size, processed_at, server_changed_at})
  end

  defp add_change_point({price_str, size}, processed_at, acc) do
    {price, ""} = Float.parse(price_str)
    Map.put(acc, price, {size, processed_at, nil})
  end
end
