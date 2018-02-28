defmodule Tai.Commands.Markets do
  alias Tai.{Exchanges, Markets.OrderBook}

  def order_book_status do
    Exchanges.Config.order_book_feed_ids
    |> fetch_order_book_status
    |> print_order_book_status
  end

  def quotes([feed_id: _feed_id, symbol: _symbol] = feed_id_and_symbol) do
    feed_id_and_symbol
    |> inside_quote
    |> format_inside_quote
    |> print_inside_quote
  end

  defp inside_quote([feed_id: _feed_id, symbol: _symbol] = feed_id_and_symbol) do
    feed_id_and_symbol
    |> OrderBook.to_name
    |> OrderBook.quotes
    |> case do
      {:ok, %{bids: bids, asks: asks}} -> [bid: bids |> List.first, ask: asks |> List.first]
    end
  end

  defp format_inside_quote([bid: nil, ask: nil]), do: format_inside_quote([bid: [price: 0, size: 0], ask: [price: 0, size: 0]])
  defp format_inside_quote([bid: bid, ask: nil]), do: format_inside_quote([bid: bid, ask: [price: 0, size: 0]])
  defp format_inside_quote([bid: nil, ask: ask]), do: format_inside_quote([bid: [price: 0, size: 0], ask: ask])
  defp format_inside_quote([bid: _bid, ask: _ask] = inside_quote), do: inside_quote

  defp print_inside_quote([
    bid: [price: bid_price, size: bid_size],
    ask: [price: ask_price, size: ask_size]
  ]) do
    IO.puts """
    #{Decimal.new(ask_price)}/#{Decimal.new(ask_size)}
    ---
    #{Decimal.new(bid_price)}/#{Decimal.new(bid_size)}
    """
  end

  defp fetch_order_book_status([_head | _tail] = feed_ids) do
    []
    |> fetch_order_book_status(feed_ids)
  end
  defp fetch_order_book_status(acc, []), do: acc
  defp fetch_order_book_status(acc, [feed_id | tail]) do
    feed_id
    |> Exchanges.Config.order_book_feed_symbols
    |> Enum.map(
      fn symbol ->
        {symbol, [feed_id: feed_id, symbol: symbol] |> inside_quote |> format_inside_quote}
      end
    )
    |> Enum.map(
      fn {symbol, [bid: [price: bid_price, size: bid_size], ask: [price: ask_price, size: ask_size]]} ->
        [
          feed_id,
          symbol,
          bid_price |> Decimal.new,
          ask_price |> Decimal.new,
          bid_size |> Decimal.new,
          ask_size |> Decimal.new
        ]
      end
    )
    |> case do
      rows -> acc |> Enum.concat(rows)
    end
    |> fetch_order_book_status(tail)
  end

  defp print_order_book_status(rows) do
    header = ["Feed", "Symbol", "Bid Price", "Ask Price", "Bid Size", "Ask Size"]

    TableRex.Table.new(rows, header)
    |> TableRex.Table.put_column_meta(:all, align: :right)
    |> TableRex.Table.render!
    |> IO.puts
  end
end
