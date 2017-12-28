defmodule Tai.Exchanges.Adapters.Gdax.Orders do
  alias Tai.OrderResponse
  alias Tai.Exchanges.Adapters.Gdax.Product
  alias Tai.Exchanges.Adapters.Gdax.OrderStatus

  def buy_limit(symbol, price, size) do
    {"buy", symbol, price, size}
    |> create_limit_order
  end

  def sell_limit(symbol, price, size) do
    {"sell", symbol, price, size}
    |> create_limit_order
  end

  defp create_limit_order(order) do
    order
    |> build_limit_order
    |> ExGdax.create_order
    |> handle_create_order
  end

  defp build_limit_order({side, symbol, price, size}) do
    %{
      "type" => "limit",
      "side" => side,
      "product_id" => Product.to_product_id(symbol),
      "price" => price,
      "size" => size
    }
  end

  defp handle_create_order({:ok, %{"id" => id, "status" => status}}) do
    {:ok, %OrderResponse{id: id, status: OrderStatus.to_atom(status)}}
  end
  defp handle_create_order({:error, message, _status_code}) do
    {:error, message}
  end
end
