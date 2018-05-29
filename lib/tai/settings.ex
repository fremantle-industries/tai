defmodule Tai.Settings do
  @moduledoc """
  Global settings
  """

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{send_orders: true}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:disable_send_orders!, _from, state) do
    new_state = Map.put(state, :send_orders, false)
    {:reply, :ok, new_state}
  end

  def handle_call(:send_orders?, _from, state) do
    send_orders = Map.get(state, :send_orders)
    {:reply, send_orders, state}
  end

  def disable_send_orders! do
    GenServer.call(__MODULE__, :disable_send_orders!)
  end

  def send_orders? do
    GenServer.call(__MODULE__, :send_orders?)
  end
end
