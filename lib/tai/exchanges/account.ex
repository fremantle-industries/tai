defmodule Tai.Exchanges.Account do
  @moduledoc """
  Uniform interface for private exchange actions
  """

  alias Tai.Trading.{Order, OrderResponses}

  @doc """
  """
  def balance(exchange_id) do
    exchange_id
    |> to_name
    |> GenServer.call(:balance)
  end

  @doc """
  Create a buy limit order on the exchange with the given

  - symbol
  - price
  - size
  """
  def buy_limit(exchange_id, symbol, price, size) do
    exchange_id
    |> to_name
    |> GenServer.call({:buy_limit, symbol, price, size})
  end

  @doc """
  Create a buy limit order from the given order struct. It returns an error tuple
  when the type is not accepted.

  {:error, %OrderResponses.InvalidOrderType{}}
  """
  def buy_limit(%Order{} = order) do
    if Order.buy_limit?(order) do
      buy_limit(order.exchange, order.symbol, order.price, order.size)
    else
      {:error, %OrderResponses.InvalidOrderType{}}
    end
  end

  @doc """
  Create a sell limit order on the exchange with the given

  - symbol
  - price
  - size
  """
  def sell_limit(exchange_id, symbol, price, size) do
    exchange_id
    |> to_name
    |> GenServer.call({:sell_limit, symbol, price, size})
  end

  @doc """
  Create a sell limit order from the given order struct. It returns an error tuple
  when the type is not accepted.

  {:error, %OrderResponses.InvalidOrderType{}}
  """
  def sell_limit(%Order{} = order) do
    if Order.sell_limit?(order) do
      sell_limit(order.exchange, order.symbol, order.price, order.size)
    else
      {:error, %OrderResponses.InvalidOrderType{}}
    end
  end

  @doc """
  Fetches the status of the order from the exchange
  """
  def order_status(exchange_id, order_id) do
    exchange_id
    |> to_name
    |> GenServer.call({:order_status, order_id})
  end

  @doc """
  Cancels the order on the exchange and returns the order_id
  """
  def cancel_order(exchange_id, order_id) do
    exchange_id
    |> to_name
    |> GenServer.call({:cancel_order, order_id})
  end

  @doc """
  Returns an atom which identifies the process for the given exchange_id

  ## Examples

    iex> Tai.Exchanges.Account.to_name(:my_test_exchange)
    :exchanges_account_my_test_exchange
  """
  def to_name(exchange_id), do: :"exchanges_account_#{exchange_id}"
end
