defmodule Tai.VenueAdapters.Mock.Stream.Connection do
  use WebSockex
  require Logger
  alias Tai.VenueAdapters.Mock
  alias Tai.Trading.OrderStore

  @type channel :: Tai.Venues.Adapter.channel()
  @type product :: Tai.Venues.Product.t()
  @type msg :: map
  @type account_config :: map
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()

  @enforce_keys [:venue_id]
  defstruct [:venue_id]

  @spec start_link(
          url: String.t(),
          venue_id: venue_id,
          channels: [channel],
          account: {account_id, account_config} | nil,
          products: [product]
        ) :: {:ok, pid}
  def start_link(url: url, venue_id: venue_id, channels: _, account: _, products: _) do
    conn = %Mock.Stream.Connection{venue_id: venue_id}
    WebSockex.start_link(url, __MODULE__, conn, name: venue_id |> to_name)
  end

  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_connect(_conn, state) do
    Tai.Events.info(%Tai.Events.StreamConnect{venue: state.venue_id})
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Tai.Events.info(%Tai.Events.StreamDisconnect{
      venue: state.venue_id,
      reason: conn_status.reason
    })

    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state.venue_id)

    {:ok, state}
  end

  def handle_frame(_frame, state), do: {:ok, state}

  @spec handle_msg(msg, venue_id) :: no_return
  defp handle_msg(msg, venue_id)

  defp handle_msg(
         %{
           "type" => "snapshot",
           "symbol" => raw_symbol,
           "bids" => bids,
           "asks" => asks
         },
         venue_id
       ) do
    symbol = String.to_atom(raw_symbol)
    processed_at = Timex.now()

    snapshot = %Tai.Markets.OrderBook{
      venue_id: venue_id,
      product_symbol: symbol,
      bids: Mock.Stream.Snapshot.normalize(bids, processed_at),
      asks: Mock.Stream.Snapshot.normalize(asks, processed_at)
    }

    Tai.Markets.OrderBook.replace(snapshot)
  end

  defp handle_msg(
         %{
           "status" => "open",
           "client_id" => client_id,
           "cumulative_qty" => raw_cumulative_qty,
           "leaves_qty" => raw_leaves_qty
         },
         _venue_id
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

    Tai.Trading.Orders.updated!(prev_order, updated_order)
  end

  defp handle_msg(
         %{
           "status" => "filled",
           "client_id" => client_id,
           "cumulative_qty" => raw_cumulative_qty
         },
         _venue_id
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

    Tai.Trading.Orders.updated!(prev_order, updated_order)
  end

  defp handle_msg(
         %{
           "status" => "canceled",
           "client_id" => client_id
         },
         _venue_id
       ) do
    {:ok, {prev_order, updated_order}} =
      %OrderStore.Actions.PassiveCancel{
        client_id: client_id,
        last_received_at: Timex.now(),
        last_venue_timestamp: Timex.now()
      }
      |> OrderStore.update()

    Tai.Trading.Orders.updated!(prev_order, updated_order)
  end

  defp handle_msg(msg, venue_id) do
    Logger.error(fn ->
      "Unhandled stream message - venue_id: #{inspect(venue_id)}, msg: #{inspect(msg)}"
    end)
  end
end
