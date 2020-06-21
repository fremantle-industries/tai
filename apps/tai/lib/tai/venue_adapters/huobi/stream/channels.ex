defmodule Tai.VenueAdapters.Huobi.Stream.Channels do
  @type product :: Tai.Venues.Product.t()
  @type venue_channel :: String.t()

  @spec market_depth(product) :: {:ok, venue_channel} | {:error, :unhandled_alias}
  def market_depth(product) do
    with {:ok, venue_symbol} <- channel_symbol(product) do
      channel =
        ["market", venue_symbol, "depth", "size_20", "high_freq"]
        |> Enum.join(".")

      {:ok, channel}
    end
  end

  @spec channel_symbol(product) :: {:ok, String.t()} | {:error, :unhandled_alias}
  def channel_symbol(product) do
    with {:ok, suffix} <- contract_type(product.alias) do
      {:ok, "#{product.venue_base}_#{suffix}"}
    end
  end

  defp contract_type("this_week"), do: {:ok, "CW"}
  defp contract_type("next_week"), do: {:ok, "NW"}
  defp contract_type("quarter"), do: {:ok, "CQ"}
  defp contract_type("next_quarter"), do: {:ok, "NQ"}
  defp contract_type(_), do: {:error, :unhandled_alias}
end
