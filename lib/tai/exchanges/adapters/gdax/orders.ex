defmodule Tai.Exchanges.Adapters.Gdax.Orders do
  alias Tai.Exchanges.Adapters.Gdax.Product

  def buy_limit(symbol, price, size) do
    %{
      "type" => "limit",
      "side" => "buy",
      "product_id" => symbol |> Product.to_product_id,
      "price" => price,
      "size" => size
    }
    |> ExGdax.create_order
    |> handle_order
  end

  def order_status(order_id) do
    order_id
    |> ExGdax.get_order
    |> case do
      {:ok, %{"status" => status}} ->
        {:ok, status |> status_to_atom}
    end
  end

  defp handle_order({:ok, %{"id" => id, "status" => status}}) do
    {:ok, %Tai.OrderResponse{id: id, status: status |> status_to_atom}}
  end

  defp handle_order({:error, message, _status_code}) do
    {:error, message}
  end

  defp status_to_atom("pending") do
    :pending
  end

  defp status_to_atom("open") do
    :open
  end
end
