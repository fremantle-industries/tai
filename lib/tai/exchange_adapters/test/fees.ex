defmodule Tai.ExchangeAdapters.Test.HydrateFees do
  use GenServer

  def start_link([exchange_id: exchange_id, accounts: _] = state) do
    name = :"#{__MODULE__}_#{exchange_id}"
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state) do
    {:ok, state, {:continue, :fetch}}
  end

  def handle_continue(:fetch, state) do
    # fetch!(state)
    {:noreply, state}
  end
end
