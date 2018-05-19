defmodule Tai.Commands.Trading do
  alias Tai.{Exchanges.Account, Trading.OrderResponses}

  def buy_limit(account_id, symbol, price, size) do
    account_id
    |> Account.buy_limit(symbol, price, size)
    |> case do
      {:ok, order_response} ->
        IO.puts(
          "create order success - id: #{order_response.id}, status: #{order_response.status}"
        )

      {:error, %OrderResponses.InsufficientFunds{}} ->
        IO.puts("create order failure - insufficient funds")
    end
  end

  def sell_limit(account_id, symbol, price, size) do
    account_id
    |> Account.sell_limit(symbol, price, size)
    |> case do
      {:ok, order_response} ->
        IO.puts(
          "create order success - id: #{order_response.id}, status: #{order_response.status}"
        )

      {:error, %OrderResponses.InsufficientFunds{}} ->
        IO.puts("create order failure - insufficient funds")
    end
  end

  def order_status(account_id, order_id) do
    account_id
    |> Account.order_status(order_id)
    |> case do
      {:ok, status} ->
        IO.puts("status: #{status}")

      {:error, message} ->
        IO.puts("error: #{message}")
    end
  end

  def cancel_order(account_id, order_id) do
    account_id
    |> Account.cancel_order(order_id)
    |> case do
      {:ok, _canceled_order_id} ->
        IO.puts("cancel order success")

      {:error, message} ->
        IO.puts("error: #{message}")
    end
  end
end
