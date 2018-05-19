defmodule Tai.Exchanges.Account do
  @moduledoc """
  Uniform interface for private exchange actions
  """

  alias Tai.Trading.{Order, OrderResponses}

  @doc """
  """
  def balance(account_id) do
    account_id
    |> to_name
    |> GenServer.call(:balance)
  end

  @doc """
  Create a buy limit order on the exchange with the given

  - symbol
  - price
  - size
  """
  def buy_limit(account_id, symbol, price, size) do
    account_id
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
      buy_limit(order.account_id, order.symbol, order.price, order.size)
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
  def sell_limit(account_id, symbol, price, size) do
    account_id
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
      sell_limit(order.account_id, order.symbol, order.price, order.size)
    else
      {:error, %OrderResponses.InvalidOrderType{}}
    end
  end

  @doc """
  Fetches the status of the order from the exchange
  """
  def order_status(account_id, order_id) do
    account_id
    |> to_name
    |> GenServer.call({:order_status, order_id})
  end

  @doc """
  Cancels the order on the exchange and returns the order_id
  """
  def cancel_order(account_id, order_id) do
    account_id
    |> to_name
    |> GenServer.call({:cancel_order, order_id})
  end

  @doc """
  Returns an atom which identifies the process for the given account_id

  ## Examples

    iex> Tai.Exchanges.Account.to_name(:my_test_small_account)
    :account_my_test_small_account
  """
  def to_name(account_id), do: :"account_#{account_id}"
end
