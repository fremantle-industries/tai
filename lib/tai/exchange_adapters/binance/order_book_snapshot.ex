defmodule Tai.ExchangeAdapters.Binance.OrderBookSnapshot do
  alias Tai.Markets

  def fetch(symbol, depth) do
    symbol
    |> Tai.Markets.Symbol.upcase()
    |> Binance.get_depth(depth)
    |> case do
      {:ok, %Binance.OrderBook{bids: bids, asks: asks}} ->
        processed_at = Timex.now()

        {
          :ok,
          %Markets.OrderBook{
            bids: bids |> to_price_levels(processed_at),
            asks: asks |> to_price_levels(processed_at)
          }
        }

      {:error, %{"code" => -1121, "msg" => "Invalid symbol."}} ->
        {:error, :invalid_symbol}
    end
  end

  defp to_price_levels(raw_price_levels, processed_at) do
    to_price_levels(raw_price_levels, processed_at, %{})
  end

  defp to_price_levels([], _processed_at, acc), do: acc

  defp to_price_levels([[price_str, size_str, _] | tail], processed_at, acc) do
    {price, _} = Float.parse(price_str)
    {size, _} = Float.parse(size_str)

    tail
    |> to_price_levels(processed_at, Map.put(acc, price, {size, processed_at, nil}))
  end
end
