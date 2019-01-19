defmodule Tai.VenueAdapters.Mock.Stream.Connection do
  use WebSockex
  alias Tai.VenueAdapters.Mock
  require Logger

  @type product :: Tai.Venues.Product.t()
  @type account_config :: map
  @type account_id :: atom

  @enforce_keys [:venue_id]
  defstruct [:venue_id]

  @spec start_link(
          url: String.t(),
          venue_id: atom,
          account: {account_id, account_config} | nil,
          products: [product]
        ) :: {:ok, pid}
  def start_link(url: url, venue_id: venue_id, account: _, products: _) do
    conn = %Mock.Stream.Connection{venue_id: venue_id}
    WebSockex.start_link(url, __MODULE__, conn, name: venue_id |> to_name)
  end

  def to_name(venue_id), do: :"#{__MODULE__}_#{venue_id}"

  def handle_connect(_conn, state) do
    Tai.Events.broadcast(%Tai.Events.StreamConnectionOk{venue_id: state.venue_id})
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Tai.Events.broadcast(%Tai.Events.StreamDisconnect{
      venue_id: state.venue_id,
      reason: conn_status.reason
    })

    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    Logger.debug(fn -> "Received raw msg: #{msg}" end)

    msg
    |> Poison.decode!()
    |> handle_msg(state.venue_id)

    {:ok, state}
  end

  def handle_frame(_frame, state), do: {:ok, state}

  @spec handle_msg(msg :: map, venue_id :: atom) :: no_return
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
end
