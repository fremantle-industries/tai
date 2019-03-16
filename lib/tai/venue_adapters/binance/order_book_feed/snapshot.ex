defmodule Tai.VenueAdapters.Binance.OrderBookFeed.Snapshot do
  def fetch(venue_id, symbol, depth) do
    exchange_symbol = Tai.ExchangeAdapters.Binance.SymbolMapping.to_binance(symbol)

    with {:ok, %Binance.OrderBook{} = binance_book} <- Binance.get_depth(exchange_symbol, depth) do
      processed_at = Timex.now()

      book = %Tai.Markets.OrderBook{
        venue_id: venue_id,
        product_symbol: symbol,
        bids: binance_book.bids |> to_price_points(processed_at),
        asks: binance_book.asks |> to_price_points(processed_at)
      }

      {:ok, book}
    end
  end

  defp to_price_points(raw_price_points, processed_at) do
    to_price_points(raw_price_points, processed_at, %{})
  end

  defp to_price_points([], _processed_at, acc), do: acc

  defp to_price_points([[price_str, size_str, _] | tail], processed_at, acc) do
    {price, _} = Float.parse(price_str)
    {size, _} = Float.parse(size_str)

    tail
    |> to_price_points(processed_at, Map.put(acc, price, {size, processed_at, nil}))
  end
end
