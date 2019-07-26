defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessMessages do
  use GenServer
  alias Tai.VenueAdapters.Bitmex.Stream

  @type t :: %Stream.ProcessMessages{
          venue_id: atom
        }

  @enforce_keys [:venue_id]
  defstruct [:venue_id]

  def start_link(venue_id: venue_id) do
    state = %Stream.ProcessMessages{venue_id: venue_id}
    GenServer.start_link(__MODULE__, state, name: venue_id |> to_name())
  end

  def init(state), do: {:ok, state}

  @spec to_name(venue_id :: atom) :: atom
  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_cast(
        {%{"table" => "publicNotifications", "data" => data, "action" => action}, _received_at},
        state
      ) do
    Tai.Events.info(%Tai.Events.Bitmex.PublicNotifications{
      venue_id: state.venue_id,
      action: action,
      data: data
    })

    {:noreply, state}
  end

  def handle_cast({%{"table" => "funding", "data" => funding}, received_at}, state) do
    Enum.each(
      funding,
      &Stream.Funding.broadcast(&1, state.venue_id, received_at)
    )

    {:noreply, state}
  end

  def handle_cast({%{"table" => "settlement", "data" => settlements}, received_at}, state) do
    Enum.each(
      settlements,
      &Stream.Settlements.broadcast(&1, state.venue_id, received_at)
    )

    {:noreply, state}
  end

  def handle_cast({%{"table" => "connected", "data" => stats}, received_at}, state) do
    Enum.each(
      stats,
      &Stream.ConnectedStats.broadcast(&1, state.venue_id, received_at)
    )

    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "liquidation", "data" => liquidations, "action" => action}, received_at},
        state
      ) do
    Enum.each(
      liquidations,
      &Stream.Liquidations.broadcast(&1, action, state.venue_id, received_at)
    )

    {:noreply, state}
  end

  def handle_cast(
        {%{"table" => "trade", "data" => trades, "action" => "insert"}, received_at},
        state
      ) do
    Enum.each(
      trades,
      &Stream.Trades.broadcast(&1, state.venue_id, received_at)
    )

    {:noreply, state}
  end

  def handle_cast({msg, _received_at}, state) do
    Tai.Events.info(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue_id,
      msg: msg
    })

    {:noreply, state}
  end
end
