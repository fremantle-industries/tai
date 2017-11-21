defmodule Tai.Exchanges.Adapters.Gdax.Quotes do
  alias Tai.Exchanges.Adapters.Gdax.Product
  alias Tai.Quote

  def quotes(symbol, start \\ Timex.now) do
    symbol
    |> Product.to_product_id
    |> ExGdax.get_order_book
    |> extract_quotes(
      Timex.diff(Timex.now, start) / 1_000_000
      |> Decimal.new
    )
  end

  defp extract_quotes(
    {
      :ok,
      %{
        "bids" => [[bid_price, bid_size, _bid_order_count]],
        "asks" => [[ask_price, ask_size, _ask_order_count]]
      }
    },
    age
  ) do
    {
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
end
