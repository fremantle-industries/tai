defmodule Tai.VenueAdapters.Binance.Stream.Snapshot do
  @type product :: Tai.Venues.Product.t()
  @type order_book :: Tai.Markets.OrderBook.t()

  @spec fetch(product, pos_integer) :: {:ok, order_book}
  def fetch(product, depth) do
    with {:ok, binance_book} <- ExBinance.Public.depth(product.venue_symbol, depth) do
      received_at = Timex.now()

      book = %Tai.Markets.OrderBook{
        venue_id: product.venue_id,
        product_symbol: product.symbol,
        last_received_at: received_at,
        bids: binance_book.bids |> to_price_points(received_at),
        asks: binance_book.asks |> to_price_points(received_at)
      }

      {:ok, book}
    end
  end

  defp to_price_points(raw_price_points, received_at) do
    raw_price_points
    |> Enum.reduce(
      %{},
      fn [raw_price, raw_size], acc ->
        {price, _} = Float.parse(raw_price)
        {size, _} = Float.parse(raw_size)
        Map.put(acc, price, {size, received_at, nil})
      end
    )
  end
end
