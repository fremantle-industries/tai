defmodule Tai.Fund do
  use GenServer
  alias Tai.Currency
  alias Tai.Exchange

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:balance, _from, state) do
    balance = exchange_balances()
              |> Currency.sum(:btc)

    {:reply, balance, state}
  end

  defp exchange_balances do
    Tai.Settings.exchange_ids
    |> Enum.map(fn(name) -> Exchange.balance(name) end)
  end

  def balance do
    GenServer.call(__MODULE__, :balance)
  end
end
