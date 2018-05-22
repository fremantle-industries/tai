defmodule Tai.ExchangeAdapters.Gdax.Account.Orders do
  @moduledoc """
  Create buy and sell orders for the GDAX adapter
  """

  alias Tai.Trading.OrderResponses
  alias Tai.ExchangeAdapters.Gdax.{Account.OrderStatus, Product}

  def buy_limit(symbol, price, size, _duration) do
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
    |> ExGdax.create_order()
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

  defp handle_create_order({
         :ok,
         %{"id" => id, "status" => status, "created_at" => created_at_str}
       }) do
    created_at = Timex.parse!(created_at_str, "{ISO:Extended}")

    order_response = %OrderResponses.Created{
      id: id,
      status: OrderStatus.to_atom(status),
      created_at: created_at
    }

    {:ok, order_response}
  end

  defp handle_create_order({:error, "Insufficient funds", _status_code}) do
    {:error, %OrderResponses.InsufficientFunds{}}
  end

  defp handle_create_order({:error, message, _status_code}) do
    {:error, message}
  end
end
