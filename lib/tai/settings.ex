defmodule Tai.Settings do
  @moduledoc """
  Global settings
  """

  use GenServer

  @enforce_keys [:send_orders]
  defstruct [:send_orders]

  def start_link(%Tai.Settings{} = settings) do
    {:ok, pid} = GenServer.start_link(__MODULE__, settings, name: __MODULE__)
    GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:create_ets_table, _from, state) do
    create_ets_table()
    upsert_items(state)
    {:reply, :ok, state}
  end

  def handle_call({:set_send_orders, val}, _from, state) do
    :ets.insert(__MODULE__, {:send_orders, val})
    {:reply, :ok, state}
  end

  def all do
    [{:send_orders, send_orders}] = :ets.lookup(__MODULE__, :send_orders)

    %Tai.Settings{
      send_orders: send_orders
    }
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

  def from_config(%Tai.Config{} = config) do
    %Tai.Settings{send_orders: config.send_orders}
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
