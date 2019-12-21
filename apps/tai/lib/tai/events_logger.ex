defmodule Tai.EventsLogger do
  use GenServer
  require Logger

  defmodule State do
    @type t :: %State{
            id: atom,
            events: module
          }

    @enforce_keys ~w(id events)a
    defstruct ~w(id events)a
  end

  @type event :: map
  @type level :: Tai.Events.level()

  @default_id :default
  @default_events Tai.Events

  def start_link(args) do
    id = Keyword.get(args, :id, @default_id)
    name = :"#{__MODULE__}_#{id}"
    events = Keyword.get(args, :events, @default_events)
    state = %State{id: id, events: events}

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(State.t()) :: {:ok, State.t()}
  def init(state) do
    state.events.firehose_subscribe()
    {:ok, state}
  end

  @spec handle_info({Tai.Event, event, level}, State.t()) :: {:noreply, State.t()}
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
