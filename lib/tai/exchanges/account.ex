defmodule Tai.Exchanges.Account do
  @moduledoc """
  Uniform interface for private exchange actions
  """

  @callback all_balances() :: {:ok, balances :: map} | {:error, reason :: term}

  @callback buy_limit(
              symbol :: atom,
              price :: float,
              size :: float,
              time_in_force :: atom()
            ) :: {:ok, order_response :: Tai.Trading.OrderResponse.t()} | {:error, reason :: term}

  @callback sell_limit(
              symbol :: atom,
              price :: float,
              size :: float,
              time_in_force :: atom
            ) :: {:ok, order_response :: Tai.Trading.OrderResponse.t()} | {:error, reason :: term}

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer

      @behaviour Tai.Exchanges.Account

      def start_link(account_id) do
        GenServer.start_link(
          __MODULE__,
          account_id,
          name: account_id |> Tai.Exchanges.Account.to_name()
        )
      end

      def init(account_id) do
        {:ok, account_id}
      end

      def handle_call(:all_balances, _from, state) do
        response = all_balances()
        {:reply, response, state}
      end

      def handle_call({:buy_limit, symbol, price, size, time_in_force}, _from, state) do
        response = buy_limit(symbol, price, size, time_in_force)
        {:reply, response, state}
      end

      def handle_call({:sell_limit, symbol, price, size, time_in_force}, _from, state) do
        response = sell_limit(symbol, price, size, time_in_force)
        {:reply, response, state}
      end
    end
  end

  @doc """
  Fetches all balances for the given account
  """
  def all_balances(account_id) do
    account_id
    |> to_name
    |> GenServer.call(:all_balances)
  end

  @doc """
  Create a buy limit order on the exchange with the given

  - symbol
  - price
  - size
  - time_in_force
  """
  def buy_limit(account_id, symbol, price, size, time_in_force \\ :ioc) do
    account_id
    |> to_name
    |> GenServer.call({:buy_limit, symbol, price, size, time_in_force})
  end

  @doc """
  Create a buy limit order from the given order struct. It returns an error tuple
  when the type is not accepted.

  {:error, %Tai.Trading.OrderResponses.InvalidOrderType{}}
  """
  def buy_limit(%Tai.Trading.Order{} = order) do
    if Tai.Trading.Order.buy_limit?(order) do
      buy_limit(order.account_id, order.symbol, order.price, order.size, order.time_in_force)
    else
      {:error, %Tai.Trading.OrderResponses.InvalidOrderType{}}
    end
  end

  @doc """
  Create a sell limit order on the exchange with the given

  - symbol
  - price
  - size
  - time_in_force
  """
  def sell_limit(account_id, symbol, price, size, time_in_force \\ :ioc) do
    account_id
    |> to_name
    |> GenServer.call({:sell_limit, symbol, price, size, time_in_force})
  end

  @doc """
  Create a sell limit order from the given order struct. It returns an error tuple
  when the type is not accepted.

  {:error, %Tai.Trading.OrderResponses.InvalidOrderType{}}
  """
  def sell_limit(%Tai.Trading.Order{} = order) do
    if Tai.Trading.Order.sell_limit?(order) do
      sell_limit(order.account_id, order.symbol, order.price, order.size, order.time_in_force)
    else
      {:error, %Tai.Trading.OrderResponses.InvalidOrderType{}}
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
