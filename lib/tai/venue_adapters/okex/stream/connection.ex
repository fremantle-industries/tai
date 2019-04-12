defmodule Tai.VenueAdapters.OkEx.Stream.Connection do
  use WebSockex
  require Logger
  alias Tai.{Events, Venues, VenueAdapters.OkEx.Stream}

  defmodule State do
    @type venue_id :: Venues.Adapter.venue_id()
    @type t :: %State{venue: venue_id}

    @enforce_keys ~w(venue)a
    defstruct ~w(venue)a
  end

  @type product :: Venues.Product.t()
  @type endpoint :: String.t()
  @type venue_id :: Venues.Adapter.venue_id()
  @type account_id :: Venues.Adapter.account_id()
  @type account_config :: map
  @type msg :: map
  @type state :: State.t()

  @spec start_link(
          endpoint: endpoint,
          venue: venue_id,
          account: {account_id, account_config} | nil,
          products: [product]
        ) :: {:ok, pid}
  def start_link(endpoint: endpoint, venue: venue, account: nil, products: products) do
    state = %State{venue: venue}
    name = venue |> to_name
    {:ok, pid} = WebSockex.start_link(endpoint, __MODULE__, state, name: name)
    subscribe_shared(pid, products)
    {:ok, pid}
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def handle_connect(_conn, state) do
    Events.info(%Events.StreamConnect{venue: state.venue})
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Events.error(%Events.StreamDisconnect{
      venue: state.venue,
      reason: conn_status.reason
    })

    {:ok, state}
  end

  def handle_frame({:binary, compressed_data}, state) do
    compressed_data
    |> :zlib.unzip()
    |> Jason.decode!()
    |> handle_msg(state.venue)

    {:ok, state}
  end

  def handle_frame({:text, _}, state), do: {:ok, state}

  defp subscribe_shared(pid, products) do
    subscribe_order_books(pid, products)
  end

  defp subscribe_order_books(pid, products) do
    channels = products |> Enum.map(&depth_channel/1)
    msg = %{"op" => "subscribe", "args" => channels}
    Tai.WebSocket.send_json_msg(pid, msg)
  end

  @futures_depth "futures/depth"
  defp depth_channel(product), do: [@futures_depth, product.venue_symbol] |> Enum.join(":")

  @spec handle_msg(msg, venue_id) :: no_return
  defp handle_msg(msg, venue)

  defp handle_msg(%{"table" => "futures/depth"} = msg, venue),
    do: venue |> process_order_books(msg)

  defp handle_msg(msg, venue), do: venue |> process_messages(msg)

  defp process_order_books(venue_id, msg) do
    venue_id
    |> Stream.ProcessOrderBooks.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end

  defp process_messages(venue_id, msg) do
    venue_id
    |> Tai.VenueAdapters.OkEx.Stream.ProcessMessages.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end
end
