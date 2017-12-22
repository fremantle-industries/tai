defmodule Tai.Exchanges.Adapters.Bitstamp.Quotes do
  # alias Tai.Exchanges.Adapters.Bitstamp.Product
  alias Tai.Quote

  def quotes(symbol, started_at \\ Timex.now) do
    symbol
    |> ExBitstamp.order_book
    |> extract_quotes(started_at)
  end

  defp extract_quotes(
    {:ok, %{"bids" => [first_bid | _bids], "asks" => [first_ask | _asks]}},
    started_at
  ) do
    age = Timex.diff(Timex.now, started_at) / 1_000_000
          |> Decimal.new
    [bid_price, bid_size] = first_bid
    [ask_price, ask_size] = first_ask

    {
      :ok,
      %Quote{
        size: Decimal.new(bid_size),
        price: Decimal.new(bid_price),
        age: age
      },
      %Quote{
        size: Decimal.new(ask_size),
        price: Decimal.new(ask_price),
        age: age
      }
    }
  end
  defp extract_quotes({:error, message}, _started_at) do
    {:error, message}
  end
end
