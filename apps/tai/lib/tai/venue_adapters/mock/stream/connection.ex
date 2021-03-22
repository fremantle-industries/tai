defmodule Tai.VenueAdapters.Mock.Stream.Connection do
  use WebSockex
  alias Tai.Trading.OrderStore
  alias Tai.Markets.OrderBook

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type t :: %State{venue: venue_id}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type stream :: Tai.Venues.Stream.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()
  @type msg :: map

  @spec start_link(
          endpoint: String.t(),
          stream: stream,
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid}
  def start_link(endpoint: endpoint, stream: stream, credential: _) do
    state = %State{venue: stream.venue.id}
    name = to_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue) do
    :"#{__MODULE__}_#{venue}"
  end

  def terminate(close_reason, state) do
    TaiEvents.warn(%Tai.Events.StreamTerminate{venue: state.venue, reason: close_reason})
  end

  def handle_connect(_conn, state) do
    TaiEvents.info(%Tai.Events.StreamConnect{venue: state.venue})
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    TaiEvents.warn(%Tai.Events.StreamDisconnect{venue: state.venue, reason: conn_status.reason})
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state)

    {:ok, state}
  end

  def handle_frame(_frame, state), do: {:ok, state}

  defp handle_msg(
         %{
           "type" => "snapshot",
           "symbol" => symbol_str,
           "bids" => bids,
           "asks" => asks
         },
         state
       ) do
    normalized_bids = bids |> normalize_snapshot_changes(:bid)
    normalized_asks = asks |> normalize_snapshot_changes(:ask)

    %OrderBook.ChangeSet{
      venue: state.venue,
      symbol: String.to_atom(symbol_str),
      last_received_at: Tai.Time.monotonic_time(),
      changes: Enum.concat(normalized_bids, normalized_asks)
    }
    |> OrderBook.replace()
  end

  defp handle_msg(
         %{
           "status" => "open",
           "client_id" => client_id,
           "cumulative_qty" => raw_cumulative_qty,
           "leaves_qty" => raw_leaves_qty
         },
         _state
       ) do
    cumulative_qty = raw_cumulative_qty |> Tai.Utils.Decimal.cast!()
    leaves_qty = raw_leaves_qty |> Tai.Utils.Decimal.cast!()

    {:ok, {prev_order, updated_order}} =
      %OrderStore.Actions.PassivePartialFill{
        client_id: client_id,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty,
        last_received_at: Tai.Time.monotonic_time(),
        last_venue_timestamp: Timex.now()
      }
      |> OrderStore.update()

    Tai.Trading.NotifyOrderUpdate.notify!(prev_order, updated_order)
  end

  defp handle_msg(
         %{
           "status" => "filled",
           "client_id" => client_id,
           "cumulative_qty" => raw_cumulative_qty
         },
         _state
       ) do
    cumulative_qty = raw_cumulative_qty |> Tai.Utils.Decimal.cast!()

    {:ok, {prev_order, updated_order}} =
      %OrderStore.Actions.PassiveFill{
        client_id: client_id,
        cumulative_qty: cumulative_qty,
        last_received_at: Tai.Time.monotonic_time(),
        last_venue_timestamp: Timex.now()
      }
      |> OrderStore.update()

    Tai.Trading.NotifyOrderUpdate.notify!(prev_order, updated_order)
  end

  defp handle_msg(
         %{
           "status" => "canceled",
           "client_id" => client_id
         },
         _state
       ) do
    {:ok, {prev_order, updated_order}} =
      %OrderStore.Actions.PassiveCancel{
        client_id: client_id,
        last_received_at: Tai.Time.monotonic_time(),
        last_venue_timestamp: Timex.now()
      }
      |> OrderStore.update()

    Tai.Trading.NotifyOrderUpdate.notify!(prev_order, updated_order)
  end

  defp handle_msg(msg, state) do
    %Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: Timex.now()
    }
    |> TaiEvents.warn()
  end

  defp normalize_snapshot_changes(venue_price_points, side) do
    venue_price_points
    |> Enum.map(fn {venue_price, venue_size} ->
      {price, ""} = Float.parse(venue_price)
      {side, price, venue_size}
    end)
    |> Enum.map(fn
      {side, price, 0.0} -> {:delete, side, price}
      {side, price, size} -> {:upsert, side, price, size}
    end)
  end
end
