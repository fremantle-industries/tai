defmodule Tai.VenueAdapters.Huobi.Stream.Channels do
  def depth(product) do
    ["market", depth_symbol(product), "depth", "size_20", "high_freq"]
    |> Enum.join(".")
  end

  def depth_symbol(product) do
    "#{product.venue_base}_#{contract_suffix(product.alias)}"
  end

  defp contract_suffix("this_week"), do: "CW"
  defp contract_suffix("next_week"), do: "NW"
  defp contract_suffix("quarter"), do: "CQ"
end
