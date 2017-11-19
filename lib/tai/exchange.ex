defmodule Tai.Exchange do
  use GenServer

  def start_link({name, config}) do
    GenServer.start_link(__MODULE__, {name, config}, name: name |> to_pid)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:balance, _from, state) do
    {:reply, state |> adapter_balance, state}
  end

  def balance(name) do
    GenServer.call(name |> to_pid, :balance)
  end

  defp to_pid(name) do
    "exchange_#{name}" |> String.to_atom
  end

  defp adapter_balance({_name, [adapter]}) do
    adapter.balance
  end

  defp adapter_balance({_name, [adapter | _config]}) do
    adapter.balance
  end
end
