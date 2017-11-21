defmodule Tai.Exchanges.Adapters.Gdax.Orders do
  alias Tai.OrderResponse
  alias Tai.Exchanges.Adapters.Gdax.Product
  alias Tai.Exchanges.Adapters.Gdax.OrderStatus

  def buy_limit(symbol, price, size) do
    %{
      "type" => "limit",
      "side" => "buy",
      "product_id" => symbol |> Product.to_product_id,
      "price" => price,
      "size" => size
    }
    |> ExGdax.create_order
    |> handle_create_order
  end

  def order_status(order_id) do
    order_id
    |> ExGdax.get_order
    |> handle_order_status
  end

  defp handle_create_order({:ok, %{"id" => id, "status" => status}}) do
    {:ok, %OrderResponse{id: id, status: status |> OrderStatus.to_atom}}
  end
  defp handle_create_order({:error, message, _status_code}) do
    {:error, message}
  end

  defp handle_order_status({:ok, %{"status" => status}}) do
    {:ok, status |> OrderStatus.to_atom}
  end
  defp handle_order_status({:error, message, _status_code}) do
    {:error, message}
  end
end
