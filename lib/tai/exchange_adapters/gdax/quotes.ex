defmodule Tai.ExchangeAdapters.Gdax.Quotes do
  alias Tai.ExchangeAdapters.Gdax.Product
  alias Tai.Quote

  def quotes(symbol, started_at \\ Timex.now) do
    symbol
    |> Product.to_product_id
    |> ExGdax.get_order_book
    |> extract_quotes(started_at)
  end

  defp extract_quotes(
    {
      :ok,
      %{
        "bids" => [[bid_price, bid_size, _bid_order_count]],
        "asks" => [[ask_price, ask_size, _ask_order_count]]
      }
    },
    started_at
  ) do
    age = Timex.diff(Timex.now, started_at) / 1_000_000
          |> Decimal.new

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
  defp extract_quotes({:error, message, _status_code}, _started_at) do
    {:error, message}
  end
end
