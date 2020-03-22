defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessOptionalChannels do
  use GenServer
  alias Tai.VenueAdapters.Bitmex.Stream

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue: venue_id}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type venue_id :: Tai.Venue.id()

  @spec start_link(venue_id: venue_id) :: GenServer.on_start()
  def start_link(venue_id: venue_id) do
    state = %State{venue: venue_id}
    name = venue_id |> to_name()

    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def init(state), do: {:ok, state}

  def handle_cast(
        {%{"table" => "publicNotifications", "data" => data, "action" => action}, _received_at},
        state
      ) do
    TaiEvents.info(%Tai.Events.Bitmex.PublicNotifications{
      venue_id: state.venue,
      action: action,
      data: data
    })

    {:noreply, state}
  end

  def handle_cast({%{"table" => "funding", "data" => funding}, received_at}, state) do
    Enum.each(
      funding,
      &Stream.Funding.broadcast(&1, state.venue, received_at)
    )

    {:noreply, state}
  end

  def handle_cast({%{"table" => "settlement", "data" => settlements}, received_at}, state) do
    Enum.each(
      settlements,
      &Stream.Settlements.broadcast(&1, state.venue, received_at)
    )

    {:noreply, state}
  end

  def handle_cast({%{"table" => "connected", "data" => stats}, received_at}, state) do
    Enum.each(
      stats,
      &Stream.ConnectedStats.broadcast(&1, state.venue, received_at)
    )

    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "liquidation", "data" => liquidations, "action" => action}, received_at},
        state
      ) do
    Enum.each(
      liquidations,
      &Stream.Liquidations.broadcast(&1, action, state.venue, received_at)
    )

    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "trade", "data" => trades, "action" => "insert"}, received_at},
        state
      ) do
    Enum.each(
      trades,
      &Stream.Trades.broadcast(&1, state.venue, received_at)
    )

    {:noreply, state}
  end

  def handle_cast({msg, received_at}, state) do
    %Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: received_at
    }
    |> TaiEvents.warn()

    {:noreply, state}
  end
end
