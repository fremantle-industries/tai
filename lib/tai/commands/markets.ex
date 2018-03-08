defmodule Tai.Commands.Markets do
  alias Tai.{Exchanges, Markets.OrderBook}

  def markets do
    Exchanges.Config.order_book_feed_ids
    |> fetch_order_book_status
    |> print_order_book_status
  end

  defp inside_quote([feed_id: _feed_id, symbol: _symbol] = feed_id_and_symbol) do
    feed_id_and_symbol
    |> OrderBook.to_name
    |> OrderBook.quotes
    |> case do
      {:ok, %{bids: bids, asks: asks}} -> [bid: bids |> List.first, ask: asks |> List.first]
    end
  end

  defp format_inside_quote([bid: nil, ask: nil]) do
    format_inside_quote([
      bid: [price: 0, size: 0, processed_at: nil, server_changed_at: nil],
      ask: [price: 0, size: 0, processed_at: nil, server_changed_at: nil]
    ])
  end
  defp format_inside_quote([bid: bid, ask: nil]) do
    format_inside_quote([
      bid: bid,
      ask: [price: 0, size: 0, processed_at: nil, server_changed_at: nil]
    ])
  end
  defp format_inside_quote([bid: nil, ask: ask]) do
    format_inside_quote([
      bid: [price: 0, size: 0, processed_at: nil, server_changed_at: nil],
      ask: ask
    ])
  end
  defp format_inside_quote([bid: _bid, ask: _ask] = inside_quote), do: inside_quote

  defp fetch_order_book_status([_head | _tail] = feed_ids) do
    feed_ids
    |> fetch_order_book_status([])
  end
  defp fetch_order_book_status([], acc), do: acc
  defp fetch_order_book_status([feed_id | tail], acc) do
    rows = feed_id
           |> Exchanges.Config.order_book_feed_symbols
           |> Enum.map(&to_feed_and_symbol_inside_quote(&1, feed_id))
           |> Enum.map(&to_order_book_status_row/1)

    tail
    |> fetch_order_book_status(acc |> Enum.concat(rows))
  end

  def to_feed_and_symbol_inside_quote(symbol, feed_id) do
    {symbol, feed_id, [feed_id: feed_id, symbol: symbol] |> inside_quote |> format_inside_quote}
  end

  defp to_order_book_status_row({
    symbol,
    feed_id,
    [
      bid: [price: bid_price, size: bid_size, processed_at: bid_processed_at, server_changed_at: bid_server_changed_at],
      ask: [price: ask_price, size: ask_size, processed_at: ask_processed_at, server_changed_at: ask_server_changed_at]
    ]
  }) do
    [
      feed_id,
      symbol,
      bid_price |> Decimal.new,
      ask_price |> Decimal.new,
      bid_size |> Decimal.new,
      ask_size |> Decimal.new,
      bid_processed_at && Timex.from_now(bid_processed_at),
      ask_processed_at && Timex.from_now(ask_processed_at),
      bid_server_changed_at && Timex.from_now(bid_server_changed_at),
      ask_server_changed_at && Timex.from_now(ask_server_changed_at)
    ]
  end

  defp print_order_book_status(rows) do
    header = ["Feed", "Symbol", "Bid Price", "Ask Price", "Bid Size", "Ask Size", "Bid Processed At", "Ask Processed At", "Bid Server Changed At", "Ask Server Changed At"]

    TableRex.Table.new(rows, header)
    |> TableRex.Table.put_column_meta(:all, align: :right)
    |> TableRex.Table.render!
    |> IO.puts
  end
end
