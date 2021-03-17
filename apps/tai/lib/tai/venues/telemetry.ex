defmodule Tai.Venues.Telemetry do
  use GenServer

  def start_link(_) do
    {:ok, pid} = GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    GenServer.call(pid, :create_ets_table)
    {:ok, pid}
  end

  @impl true
  def init(state) do
    Tai.SystemBus.subscribe({:venues, :stream})
    {:ok, state}
  end

  @impl true
  def handle_call(:create_ets_table, _from, state) do
    :ets.new(__MODULE__, [:set, :protected, :named_table])
    {:reply, :ok, state}
  end

  @counters ~w(connect disconnect terminate)a
  @impl true
  def handle_info({:venues, :stream, counter_type, venue} = key, state) when counter_type in @counters do
    count = :ets.update_counter(__MODULE__, key, 1, {key, 0})
    :telemetry.execute(
      [:tai, :venues, :stream, counter_type],
      %{total: count},
      %{venue: venue}
    )

    {:noreply, state}
  end
end
