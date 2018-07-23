defmodule Tai.Exchanges.Account do
  @moduledoc """
  Uniform interface for private exchange actions
  """

  @type order :: Tai.Trading.Order.t()
  @type order_response :: Tai.Trading.OrderResponse.t()
  @type credential_error :: Tai.CredentialError.t()
  @type timeout_error :: Tai.TimeoutError.t()
  @type insufficient_balance_error :: Tai.Trading.InsufficientBalanceError.t()
  @type invalid_order_type_error :: Tai.Trading.OrderResponses.InvalidOrderType.t()

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

      def start_link([exchange_id: exchange_id, account_id: account_id] = state) do
        GenServer.start_link(
          __MODULE__,
          state,
          name: Tai.Exchanges.Account.to_name(exchange_id, account_id)
        )
      end

      def init(state) do
        {:ok, state}
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
  @spec all_balances(atom, atom) :: {:ok, map} | {:error, credential_error | timeout_error}
  def all_balances(exchange_id, account_id) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call(:all_balances)
  end

  @doc """
  Create a buy limit order on the exchange with the given

  - symbol
  - price
  - size
  - time_in_force
  """
  @spec buy_limit(atom, atom, atom, float, float, atom) ::
          {:ok, order_response} | {:error, insufficient_balance_error}
  def buy_limit(exchange_id, account_id, symbol, price, size, time_in_force \\ :ioc) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:buy_limit, symbol, price, size, time_in_force})
  end

  @doc """
  Create a buy limit order from the given order struct. It returns an error tuple
  when the type is not accepted.

  {:error, %Tai.Trading.OrderResponses.InvalidOrderType{}}
  """
  @spec buy_limit(order) ::
          {:ok, order_response} | {:error, invalid_order_type_error | insufficient_balance_error}
  def buy_limit(%Tai.Trading.Order{} = order) do
    if Tai.Trading.Order.buy_limit?(order) do
      buy_limit(
        order.exchange_id,
        order.account_id,
        order.symbol,
        order.price,
        order.size,
        order.time_in_force
      )
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
  def sell_limit(exchange_id, account_id, symbol, price, size, time_in_force \\ :ioc) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:sell_limit, symbol, price, size, time_in_force})
  end

  @doc """
  Create a sell limit order from the given order struct. It returns an error tuple
  when the type is not accepted.

  {:error, %Tai.Trading.OrderResponses.InvalidOrderType{}}
  """
  def sell_limit(%Tai.Trading.Order{} = order) do
    if Tai.Trading.Order.sell_limit?(order) do
      sell_limit(
        order.exchange_id,
        order.account_id,
        order.symbol,
        order.price,
        order.size,
        order.time_in_force
      )
    else
      {:error, %Tai.Trading.OrderResponses.InvalidOrderType{}}
    end
  end

  @doc """
  Fetches the status of the order from the exchange
  """
  def order_status(exchange_id, account_id, order_id) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:order_status, order_id})
  end

  @doc """
  Cancels the order on the exchange and returns the order_id
  """
  def cancel_order(exchange_id, account_id, order_id) do
    exchange_id
    |> to_name(account_id)
    |> GenServer.call({:cancel_order, order_id})
  end

  @doc """
  Returns an atom which identifies the process for the given account_id

  ## Examples

    iex> Tai.Exchanges.Account.to_name(:my_test_exchange, :my_test_account)
    :"Elixir.Tai.Exchanges.Account_my_test_exchange_my_test_account"
  """
  def to_name(exchange_id, account_id),
    do: :"#{Tai.Exchanges.Account}_#{exchange_id}_#{account_id}"
end
