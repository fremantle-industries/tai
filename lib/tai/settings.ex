defmodule Tai.Settings do
  @moduledoc """
  Global settings
  """

  use GenServer

  def start_link(settings) do
    GenServer.start_link(
      __MODULE__,
      settings,
      name: __MODULE__
    )
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:set_send_orders, val}, _from, state) do
    new_state = Map.put(state, :send_orders, val)
    {:reply, :ok, new_state}
  end

  def handle_call(:send_orders?, _from, state) do
    send_orders = Map.get(state, :send_orders)
    {:reply, send_orders, state}
  end

  def all do
    GenServer.call(__MODULE__, :all)
  end

  def disable_send_orders! do
    GenServer.call(__MODULE__, {:set_send_orders, false})
  end

  def enable_send_orders! do
    GenServer.call(__MODULE__, {:set_send_orders, true})
  end

  def send_orders? do
    GenServer.call(__MODULE__, :send_orders?)
  end
end
