defmodule Tai.VenueAdapters.OkEx.Stream.Connection do
  use WebSockex
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
  def start_link(endpoint: endpoint, venue: venue, account: account, products: products) do
    state = %State{venue: venue}
    name = venue |> to_name
    {:ok, pid} = WebSockex.start_link(endpoint, __MODULE__, state, name: name)

    if account do
      login(pid, account)
      subscribe_orders(pid, products)
    end

    subscribe_depth(pid, products)
    subscribe_trade(pid, products)
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

  defp login(pid, account) do
    args = account |> auth_args()
    msg = %{"op" => "login", "args" => args}
    Tai.WebSocket.send_json_msg(pid, msg)
  end

  @method "GET"
  @path "/users/self/verify"
  defp auth_args({
         _account_id,
         %{api_key: api_key, api_secret: api_secret, api_passphrase: api_passphrase}
       }) do
    timestamp = ExOkex.Auth.timestamp()
    signed = ExOkex.Auth.sign(timestamp, @method, @path, %{}, api_secret)

    [
      api_key,
      api_passphrase,
      timestamp,
      signed
    ]
  end

  @depth "depth"
  @trade "trade"
  @order "order"

  defp subscribe_orders(pid, products) do
    channels = products |> Enum.map(&channel(&1, @order))
    msg = %{"op" => "subscribe", "args" => channels}
    Tai.WebSocket.send_json_msg(pid, msg)
  end

  defp subscribe_depth(pid, products) do
    channels = products |> Enum.map(&channel(&1, @depth))
    msg = %{"op" => "subscribe", "args" => channels}
    Tai.WebSocket.send_json_msg(pid, msg)
  end

  defp subscribe_trade(pid, products) do
    channels = products |> Enum.map(&channel(&1, @trade))
    msg = %{"op" => "subscribe", "args" => channels}
    Tai.WebSocket.send_json_msg(pid, msg)
  end

  defp channel(product, name) do
    prefix = product |> channel_prefix()
    "#{prefix}/#{name}:#{product.venue_symbol}"
  end

  defp channel_prefix(%Tai.Venues.Product{type: :future}), do: :futures
  defp channel_prefix(product), do: product.type

  @spec handle_msg(msg, venue_id) :: no_return
  defp handle_msg(msg, venue)

  @futures_depth "futures/depth"
  @swap_depth "swap/depth"
  defp handle_msg(%{"table" => table} = msg, venue)
       when table == @futures_depth or table == @swap_depth,
       do: venue |> process_order_books(msg)

  @futures_order "futures/order"
  @swap_order "swap/order"
  defp handle_msg(%{"table" => table} = msg, venue)
       when table == @futures_order or table == @swap_order,
       do: venue |> process_auth(msg)

  defp handle_msg(msg, venue), do: venue |> process_messages(msg)

  defp process_order_books(venue_id, msg) do
    venue_id
    |> Stream.ProcessOrderBooks.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end

  defp process_auth(venue_id, msg) do
    venue_id
    |> Stream.ProcessAuth.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end

  defp process_messages(venue_id, msg) do
    venue_id
    |> Stream.ProcessMessages.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end
end
