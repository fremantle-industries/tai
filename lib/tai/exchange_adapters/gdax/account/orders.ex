defmodule Tai.ExchangeAdapters.Gdax.Account.Orders do
  @moduledoc """
  Create buy and sell orders for the GDAX adapter
  """

  alias Tai.ExchangeAdapters.Gdax.Product

  def buy_limit(symbol, price, size, time_in_force, credentials) do
    {"buy", symbol, price, size}
    |> create_limit_order(time_in_force, credentials)
  end

  def sell_limit(symbol, price, size, time_in_force, credentials) do
    {"sell", symbol, price, size}
    |> create_limit_order(time_in_force, credentials)
  end

  defp create_limit_order(order, time_in_force, credentials) do
    order
    |> to_params
    |> ExGdax.create_order(credentials)
    |> handle_create_order(time_in_force)
  end

  # TODO: this should include time in force
  defp to_params({side, symbol, price, size}) do
    %{
      "type" => "limit",
      "side" => side,
      "product_id" => Product.to_product_id(symbol),
      "price" => price,
      "size" => size
    }
  end

  defp handle_create_order(
         {
           :ok,
           %{
             "id" => id,
             "status" => status,
             "size" => size,
             "filled_size" => filled_size
           }
         },
         time_in_force
       ) do
    response = %Tai.Trading.OrderResponse{
      id: id,
      status: tai_status(status),
      time_in_force: time_in_force,
      original_size: Decimal.new(size),
      executed_size: Decimal.new(filled_size)
    }

    {:ok, response}
  end

  defp handle_create_order({:error, "Insufficient funds" = reason, _status_code}, _time_in_force) do
    {:error, %Tai.Trading.InsufficientBalanceError{reason: reason}}
  end

  defp handle_create_order({:error, reason, _status_code}, _time_in_force) do
    {:error, reason}
  end

  defp tai_status("pending"), do: Tai.Trading.OrderStatus.pending()
end
