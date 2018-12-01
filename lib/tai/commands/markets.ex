defmodule Tai.Commands.Markets do
  @moduledoc """
  Display the bid/ask for each symbol on all order book feeds
  """

  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Product",
    "Bid Price",
    "Ask Price",
    "Bid Size",
    "Ask Size",
    "Bid Processed At",
    "Bid Server Changed At",
    "Ask Processed At",
    "Ask Server Changed At"
  ]

  @spec markets :: no_return
  def markets do
    Tai.Exchanges.ProductStore.all()
    |> fetch_inside_quotes
    |> format_rows
    |> sort_rows
    |> render!(@header)
  end

  defp fetch_inside_quotes(products) when is_list(products) do
    products
    |> Enum.map(fn p -> {p.exchange_id, p.symbol} end)
    |> Enum.map(fn {venue_id, symbol} ->
      {:ok, inside_quote} = Tai.Markets.OrderBook.inside_quote(venue_id, symbol)
      {venue_id, symbol, inside_quote}
    end)
  end

  defp format_rows(products_with_inside_quote) do
    products_with_inside_quote
    |> Enum.map(fn {venue_id, symbol, %Tai.Markets.Quote{bid: bid, ask: ask}} ->
      [
        venue_id,
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

  defp sort_rows(rows), do: rows |> Enum.sort(&(&1 < &2))

  defp format_row(row) when is_list(row), do: row |> Enum.map(&format_col/1)
  defp format_col({nil, _}), do: format_col(nil)
  defp format_col({receiver, message}), do: receiver |> get_in([message]) |> format_col
  defp format_col(num) when is_number(num), do: num |> to_decimal
  defp format_col(%DateTime{} = date), do: Timex.from_now(date)
  defp format_col(nil), do: "~"
  defp format_col(pass_through), do: pass_through

  defp to_decimal(val) when is_float(val), do: val |> Decimal.from_float()
  defp to_decimal(val), do: val |> Decimal.new()
end
