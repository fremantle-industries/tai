defmodule Tai.Exchange do
  use GenServer

  def start_link({name, adapter_config}) do
    name
    |> to_pid
    |> (&GenServer.start_link(__MODULE__, adapter_config, name: &1)).()
  end

  def init(adapter_config) do
    {:ok, adapter_config}
  end

  def handle_call(:balance, _from, [adapter | opts]) do
    adapter.balance
    |> (&{:reply, &1, [adapter | opts]}).()
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
