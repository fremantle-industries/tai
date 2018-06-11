defmodule Tai.ExchangeAdapters.Binance.Account do
  @moduledoc """
  Execute private exchange actions for the Binance account
  """

  use GenServer

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
    {:reply, Tai.ExchangeAdapters.Binance.Account.AllBalances.fetch(), state}
  end

  def handle_call({:buy_limit, symbol, price, size, time_in_force}, _from, state) do
    response =
      Tai.ExchangeAdapters.Binance.Account.Orders.buy_limit(symbol, price, size, time_in_force)

    {:reply, response, state}
  end

  def handle_call({:sell_limit, symbol, price, size, time_in_force}, _from, state) do
    response =
      Tai.ExchangeAdapters.Binance.Account.Orders.sell_limit(symbol, price, size, time_in_force)

    {:reply, response, state}
  end
end
