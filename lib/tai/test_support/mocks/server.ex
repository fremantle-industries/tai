defmodule Tai.TestSupport.Mocks.Server do
  use GenServer

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  def init(:ok) do
    {:ok, :ok}
  end

  def handle_call(:create_ets_table, _from, state) do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
    {:reply, :ok, state}
  end

  def handle_call({:insert, key, response}, _from, state) do
    record = {key, response}
    :ets.insert(__MODULE__, record)
    {:reply, :ok, state}
  end

  def handle_call({:eject, key}, _from, state) do
    result =
      with [{_k, response}] <- :ets.lookup(__MODULE__, key) do
        {:ok, response}
      else
        [] ->
          {:error, :not_found}
      end

    {:reply, result, state}
  end

  def insert(key, response) do
    GenServer.call(__MODULE__, {:insert, key, response})
  end

  def eject(key) do
    GenServer.call(__MODULE__, {:eject, key})
  end
end
