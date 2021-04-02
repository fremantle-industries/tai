defmodule Tai.EventsLogger do
  use GenServer

  @type event :: struct
  @type level :: TaiEvents.level()

  @callback log(level, event) :: term

  defmodule State do
    @type t :: %State{
            id: atom,
            events: module,
            logger: module
          }

    @enforce_keys ~w[id events logger]a
    defstruct ~w[id events logger]a
  end

  @default_id :default
  @default_events TaiEvents
  @default_logger Tai.EventsLogger.DefaultLogger

  def start_link(args) do
    id = Keyword.get(args, :id, @default_id)
    name = :"#{__MODULE__}_#{id}"
    events = Keyword.get(args, :events, @default_events)
    logger = Keyword.get(args, :logger) || @default_logger
    state = %State{id: id, events: events, logger: logger}

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec init(State.t()) :: {:ok, State.t()}
  def init(state) do
    state.events.firehose_subscribe()
    {:ok, state}
  end

  @spec handle_info({TaiEvents.Event, event, level}, State.t()) :: {:noreply, State.t()}
  def handle_info({TaiEvents.Event, event, level}, state) do
    state.logger.log(level, event)
    {:noreply, state}
  end
end

defmodule Tai.EventsLogger.DefaultLogger do
  @behaviour Tai.EventsLogger

  require Logger

  def log(:error, event) do
    event |> TaiEvents.Event.encode!() |> Logger.error()
  end

  def log(:warn, event) do
    event |> TaiEvents.Event.encode!() |> Logger.warn()
  end

  def log(:info, event) do
    event |> TaiEvents.Event.encode!() |> Logger.info()
  end

  def log(:debug, event) do
    event |> TaiEvents.Event.encode!() |> Logger.debug()
  end
end
