defmodule Tai.Exchange do
  use GenServer

  def start_link({name, adapter}) do
    name
    |> to_pid
    |> (&GenServer.start_link(__MODULE__, adapter, name: &1)).()
  end

  def init(adapter) do
    {:ok, adapter}
  end

  def handle_call(:balance, _from, adapter) do
    adapter.balance
    |> (&{:reply, &1, adapter}).()
  end

  def balance(name) do
    name
    |> to_pid
    |> GenServer.call(:balance)
  end

  defp to_pid(name) do
    "exchange_#{name}" |> String.to_atom
  end
end
