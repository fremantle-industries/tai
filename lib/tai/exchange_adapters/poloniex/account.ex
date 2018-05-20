defmodule Tai.ExchangeAdapters.Poloniex.Account do
  @moduledoc """
  Execute private exchange actions for the Poloniex account
  """

  use GenServer

  alias Tai.Exchanges.Account
  alias Tai.ExchangeAdapters.Poloniex.Account.{AllBalances}

  def start_link(account_id) do
    GenServer.start_link(__MODULE__, account_id, name: account_id |> Account.to_name())
  end

  def init(account_id) do
    {:ok, account_id}
  end

  def handle_call(:all_balances, _from, state) do
    {:reply, AllBalances.fetch(), state}
  end
end
