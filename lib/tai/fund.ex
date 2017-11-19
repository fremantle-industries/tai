defmodule Tai.Fund do
  use GenServer

  def start_link(state) do
    GenServer.start_link(
      __MODULE__,
      state,
      name: __MODULE__
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:balance, _from, state) do
    Tai.Settings.exchange_ids
    |> Enum.map(&Tai.Exchange.balance/1)
    |> Tai.Currency.sum
    |> (&{:reply, &1, state}).()
  end

  def balance do
    GenServer.call(__MODULE__, :balance)
  end
end
