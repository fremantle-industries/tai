defmodule Tai.EventsLogger do
  use GenServer
  require Logger

  @type event :: map
  @type level :: Tai.Events.level()
  @type state :: :ok

  @default_id :default

  def start_link(args) do
    id = Keyword.get(args, :id, @default_id)
    name = :"#{__MODULE__}_#{id}"

    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @spec init(state) :: {:ok, state}
  def init(state) do
    Tai.Events.firehose_subscribe()
    {:ok, state}
  end

  @spec handle_info({Tai.Event, event, level}, state) :: {:noreply, state}
  def handle_info({Tai.Event, event, :error}, state) do
    event |> Tai.Event.encode!() |> Logger.error()
    {:noreply, state}
  end

  def handle_info({Tai.Event, event, :warn}, state) do
    event |> Tai.Event.encode!() |> Logger.warn()
    {:noreply, state}
  end

  def handle_info({Tai.Event, event, :info}, state) do
    event |> Tai.Event.encode!() |> Logger.info()
    {:noreply, state}
  end

  def handle_info({Tai.Event, event, :debug}, state) do
    event |> Tai.Event.encode!() |> Logger.debug()
    {:noreply, state}
  end
end
