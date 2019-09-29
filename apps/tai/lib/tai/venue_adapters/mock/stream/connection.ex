defmodule Tai.VenueAdapters.Mock.Stream.Connection do
  use WebSockex
  alias Tai.Trading.OrderStore
  alias Tai.Markets.OrderBook
  alias Tai.Events

  defmodule State do
    @type venue_id :: Tai.Venues.Adapter.venue_id()
    @type t :: %State{venue_id: venue_id}

    @enforce_keys ~w(venue_id)a
    defstruct ~w(venue_id)a
  end

  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type channel :: Tai.Venues.Adapter.channel()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type account_config :: map
  @type product :: Tai.Venues.Product.t()
  @type msg :: map

  @spec start_link(
          url: String.t(),
          venue_id: venue_id,
          channels: [channel],
          account: {account_id, account_config} | nil,
          products: [product]
        ) :: {:ok, pid}
  def start_link(url: url, venue_id: venue_id, channels: _, account: _, products: _) do
    conn = %State{venue_id: venue_id}
    name = venue_id |> to_name

    WebSockex.start_link(url, __MODULE__, conn, name: name)
  end

  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_connect(_conn, state) do
    %Events.StreamConnect{venue: state.venue_id}
    |> Events.info()

    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    %Events.StreamDisconnect{
      venue: state.venue_id,
      reason: conn_status.reason
    }
    |> Events.info()

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
      venue: state.venue_id,
      symbol: String.to_atom(symbol_str),
      last_received_at: Timex.now(),
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
    cumulative_qty = raw_cumulative_qty |> Decimal.cast()
    leaves_qty = raw_leaves_qty |> Decimal.cast()

    {:ok, {prev_order, updated_order}} =
      %OrderStore.Actions.PassivePartialFill{
        client_id: client_id,
        cumulative_qty: cumulative_qty,
        leaves_qty: leaves_qty,
        last_received_at: Timex.now(),
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
    cumulative_qty = raw_cumulative_qty |> Decimal.cast()

    {:ok, {prev_order, updated_order}} =
      %OrderStore.Actions.PassiveFill{
        client_id: client_id,
        cumulative_qty: cumulative_qty,
        last_received_at: Timex.now(),
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
        last_received_at: Timex.now(),
        last_venue_timestamp: Timex.now()
      }
      |> OrderStore.update()

    Tai.Trading.NotifyOrderUpdate.notify!(prev_order, updated_order)
  end

  defp handle_msg(msg, state) do
    %Events.StreamMessageUnhandled{
      venue_id: state.venue_id,
      msg: msg,
      received_at: Timex.now()
    }
    |> Events.warn()
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
