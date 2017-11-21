defmodule Tai.Exchanges.Adapters.Gdax do
  alias Tai.Exchanges.Adapters.Gdax.Product

  defdelegate price(symbol), to: Tai.Exchanges.Adapters.Gdax.Price
  defdelegate balance, to: Tai.Exchanges.Adapters.Gdax.Balance

  def quotes(symbol, start \\ Timex.now) do
    symbol
    |> Product.to_product_id
    |> ExGdax.get_order_book
    |> case do
      {
        :ok,
        %{
          "bids" => [[bid_price, bid_size, _bid_order_count]],
          "asks" => [[ask_price, ask_size, _ask_order_count]]
        }
      } ->
        age = Decimal.new(Timex.diff(Timex.now, start) / 1_000_000)
        {
          %Tai.Quote{
            size: Decimal.new(bid_size),
            price: Decimal.new(bid_price),
            age: age
          },
          %Tai.Quote{
            size: Decimal.new(ask_size),
            price: Decimal.new(ask_price),
            age: age
          }
        }
    end
  end

  def buy_limit(symbol, price, size) do
    %{
      "type" => "limit",
      "side" => "buy",
      "product_id" => symbol |> Product.to_product_id,
      "price" => price,
      "size" => size
    }
    |> ExGdax.create_order
    |> case do
      {:ok, %{"id" => id, "status" => status}} ->
        {:ok, %Tai.OrderResponse{id: id, status: status |> parse_order_status}}
      {:error, message, _status_code} ->
        {:error, message}
    end
  end

  def parse_order_status(status) do
    case status do
      "pending" -> :pending
    end
  end
end
