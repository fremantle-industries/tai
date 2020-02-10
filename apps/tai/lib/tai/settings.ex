defmodule Tai.Settings do
  @moduledoc """
  Run time settings
  """

  use GenServer
  alias __MODULE__

  @enforce_keys ~w(send_orders)a
  defstruct ~w(send_orders)a

  def start_link(%Tai.Config{} = config) do
    state = %Settings{
      send_orders: config.send_orders
    }

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def disable_send_orders! do
    GenServer.call(__MODULE__, {:set_send_orders, false})
  end

  def enable_send_orders! do
    GenServer.call(__MODULE__, {:set_send_orders, true})
  end

  def send_orders? do
    [{:send_orders, send_orders}] = :ets.lookup(__MODULE__, :send_orders)
    send_orders
  end

  def all do
    %Settings{send_orders: send_orders?()}
  end

  def init(state) do
    {
      :ok,
      state,
      {:continue, :create_ets_table}
    }
  end

  def handle_continue(:create_ets_table, state) do
    create_ets_table()
    upsert_items(state)
    {:noreply, state}
  end

  def handle_call({:set_send_orders, val}, _from, state) do
    :ets.insert(__MODULE__, {:send_orders, val})
    {:reply, :ok, state}
  end

  defp create_ets_table do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
  end

  defp upsert_items(settings) do
    settings
    |> Map.to_list()
    |> Enum.filter(fn {k, _} -> k != :__struct__ end)
    |> Enum.each(fn item -> :ets.insert(__MODULE__, item) end)
  end
end
