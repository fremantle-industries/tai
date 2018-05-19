defmodule Tai.Commands.Markets do
  @moduledoc """
  Display the bid/ask for each symbol on all order book feeds
  """

  alias Tai.Exchanges
  alias Tai.Markets.{OrderBook, Quote}
  alias TableRex.Table

  def markets do
    Exchanges.Config.order_book_feed_ids()
    |> group_rows
    |> fetch_rows
    |> format_rows
    |> render!
  end

  defp group_rows(feed_ids) do
    feed_ids
    |> Enum.reduce(
      [],
      fn feed_id, acc ->
        feed_id
        |> Exchanges.Config.order_book_feed_symbols()
        |> Enum.reduce(
          acc,
          fn symbol, acc -> [{feed_id, symbol} | acc] end
        )
      end
    )
    |> Enum.reverse()
  end

  defp fetch_rows(groups) when is_list(groups) do
    groups
    |> Enum.map(fn {feed_id, symbol} ->
      {:ok, inside_quote} = OrderBook.inside_quote(feed_id, symbol)
      {feed_id, symbol, inside_quote}
    end)
  end

  defp format_rows(groups_with_quotes) when is_list(groups_with_quotes) do
    groups_with_quotes
    |> Enum.map(fn {feed_id, symbol, %Quote{bid: bid, ask: ask}} ->
      [
        feed_id,
        symbol,
        {bid, :price},
        {ask, :price},
        {bid, :size},
        {ask, :size},
        {bid, :processed_at},
        {bid, :server_changed_at},
        {ask, :processed_at},
        {ask, :server_changed_at}
      ]
      |> format_row
    end)
  end

  defp render!(rows) do
    header = [
      "Feed",
      "Symbol",
      "Bid Price",
      "Ask Price",
      "Bid Size",
      "Ask Size",
      "Bid Processed At",
      "Bid Server Changed At",
      "Ask Processed At",
      "Ask Server Changed At"
    ]

    rows
    |> Table.new(header)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end

  defp format_row(row) when is_list(row), do: row |> Enum.map(&format_col/1)
  defp format_col({nil, _}), do: format_col(nil)
  defp format_col({receiver, message}), do: receiver |> get_in([message]) |> format_col
  defp format_col(num) when is_number(num), do: Decimal.new(num)
  defp format_col(%DateTime{} = date), do: Timex.from_now(date)
  defp format_col(nil), do: "~"
  defp format_col(pass_through), do: pass_through
end
