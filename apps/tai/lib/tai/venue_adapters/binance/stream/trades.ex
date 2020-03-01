defmodule Tai.VenueAdapters.Binance.Stream.Trades do
  # {
  #   "e": "trade",     // Event type
  #   "E": 123456789,   // Event time
  #   "s": "BNBBTC",    // Symbol
  #   "t": 12345,       // Trade ID
  #   "p": "0.001",     // Price
  #   "q": "100",       // Quantity
  #   "b": 88,          // Buyer order ID
  #   "a": 50,          // Seller order ID
  #   "T": 123456785,   // Trade time
  #   "m": true,        // Is the buyer the market maker?
  #   "M": true         // Ignore
  # }
  def broadcast(
        %{
          "s" => venue_symbol,
          "T" => unix_timestamp,
          "p" => price,
          "q" => qty,
          "m" => side,
          "t" => venue_trade_id
        },
        venue_id,
        received_at
      ) do
    {:ok, product} = Tai.Venues.ProductStore.find_by_venue_symbol({venue_id, venue_symbol})
    {:ok, timestamp} = DateTime.from_unix(unix_timestamp, :millisecond)

    TaiEvents.info(%Tai.Events.Trade{
      venue_id: venue_id,
      symbol: product.symbol,
      received_at: received_at,
      timestamp: timestamp,
      price: price,
      qty: qty,
      side: side |> normalize_side,
      venue_trade_id: venue_trade_id
    })
  end

  # Translation may be incorrect: 买方是否是做市方。如true，则此次成交是一个主动卖出单，否则是一个主动买入单。
  # https://github.com/binance-exchange/binance-official-api-docs/blob/master/web-socket-streams_CN.md#%E9%80%90%E7%AC%94%E4%BA%A4%E6%98%93
  defp normalize_side(true), do: :sell
  defp normalize_side(false), do: :buy
end
