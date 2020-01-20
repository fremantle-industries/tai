defmodule Tai.Commands.Markets do
  @moduledoc """
  Display the bid/ask for each symbol on all order book feeds
  """

  import Tai.Commands.Table, only: [render!: 2]
  alias Tai.Markets.Quote

  @header [
    "Venue",
    "Product",
    "Bid Price",
    "Ask Price",
    "Bid Size",
    "Ask Size"
  ]

  @spec markets :: no_return
  def markets do
    Tai.Markets.QuoteStore.all()
    |> format_rows
    |> sort_rows
    |> render!(@header)
  end

  defp format_rows(market_quotes) do
    market_quotes
    |> Enum.map(fn market_quote ->
      inside_bid = Quote.inside_bid(market_quote)
      inside_ask = Quote.inside_ask(market_quote)

      [
        market_quote.venue_id,
        market_quote.product_symbol,
        {inside_bid, :price},
        {inside_ask, :price},
        {inside_bid, :size},
        {inside_ask, :size}
      ]
      |> format_row
    end)
  end

  defp sort_rows(rows), do: rows |> Enum.sort(&(&1 < &2))

  defp format_row(row) when is_list(row), do: row |> Enum.map(&format_col/1)

  defp format_col({nil, _}), do: format_col(nil)
  defp format_col({receiver, message}), do: receiver |> get_in([message]) |> format_col

  defp format_col(num) when is_number(num),
    do: num |> Decimal.cast() |> Decimal.reduce() |> Decimal.to_string(:normal)

  defp format_col(%DateTime{} = date), do: Timex.from_now(date)
  defp format_col(nil), do: "~"
  defp format_col(pass_through), do: pass_through
end
