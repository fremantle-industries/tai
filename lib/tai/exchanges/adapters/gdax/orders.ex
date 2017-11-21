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

  def handle_order({:ok, %{"id" => id, "status" => status}}) do
    {:ok, %Tai.OrderResponse{id: id, status: status |> status_to_atom}}
  end

  def handle_order({:error, message, _status_code}) do
    {:error, message}
  end

  def status_to_atom("pending") do
    :pending
  end
end
