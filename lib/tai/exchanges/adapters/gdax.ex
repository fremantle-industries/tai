defmodule Tai.Exchanges.Adapters.Gdax do
  alias Tai.Exchanges.Adapters.Gdax.Product

  defdelegate price(symbol), to: Tai.Exchanges.Adapters.Gdax.Price
  defdelegate balance, to: Tai.Exchanges.Adapters.Gdax.Balance
  defdelegate quotes(symbol), to: Tai.Exchanges.Adapters.Gdax.Quotes

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
