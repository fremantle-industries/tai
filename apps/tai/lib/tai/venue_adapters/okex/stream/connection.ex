defmodule Tai.VenueAdapters.OkEx.Stream.Connection do
  use WebSockex
  alias Tai.VenueAdapters.OkEx.Stream

  defmodule State do
    @type product :: Tai.Venues.Product.t()
    @type venue_id :: Tai.Venue.id()
    @type credential_id :: Tai.Venue.credential_id()
    @type channel_name :: atom
    @type route :: :auth | :order_books | :optional_channels
    @type t :: %State{
            venue: venue_id,
            routes: %{required(route) => atom},
            channels: [channel_name],
            credential: {credential_id, map},
            products: [product],
            heartbeat_timer: reference | nil,
            heartbeat_timeout_timer: reference | nil
          }

    @enforce_keys ~w[venue routes channels credential products]a
    defstruct ~w[venue routes channels credential products heartbeat_timer heartbeat_timeout_timer]a
  end

  @type stream :: Tai.Venues.Stream.t()
  @type endpoint :: String.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.account()
  @type msg :: map | String.t()
  @type state :: State.t()

  @spec start_link(
          endpoint: endpoint,
          stream: stream,
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid}
  def start_link(endpoint: endpoint, stream: stream, credential: credential) do
    routes = %{
      auth: stream.venue.id |> Stream.ProcessAuth.to_name(),
      order_books: stream.venue.id |> Stream.RouteOrderBooks.to_name(),
      optional_channels: stream.venue.id |> Stream.ProcessOptionalChannels.to_name()
    }

    state = %State{
      venue: stream.venue.id,
      routes: routes,
      channels: stream.venue.channels,
      credential: credential,
      products: stream.products
    }

    name = to_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def terminate(close_reason, state) do
    TaiEvents.warn(%Tai.Events.StreamTerminate{venue: state.venue, reason: close_reason})
  end

  def handle_connect(_conn, state) do
    TaiEvents.info(%Tai.Events.StreamConnect{venue: state.venue})
    send(self(), :init_subscriptions)
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    TaiEvents.warn(%Tai.Events.StreamDisconnect{
      venue: state.venue,
      reason: conn_status.reason
    })

    {:ok, state}
  end

  @optional_channels [:trades]
  def handle_info(:init_subscriptions, state) do
    if state.credential, do: send(self(), :login)
    send(self(), {:subscribe, :depth})

    state.channels
    |> Enum.each(fn c ->
      if Enum.member?(@optional_channels, c) do
        send(self(), {:subscribe, c})
      else
        TaiEvents.warn(%Tai.Events.StreamChannelInvalid{
          venue: state.venue,
          name: c,
          available: @optional_channels
        })
      end
    end)

    state = state |> schedule_heartbeat()

    {:ok, state}
  end

  def handle_info(:login, state) do
    args = Stream.Auth.args(state.credential)
    msg = %{op: "login", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :orders}, state) do
    args = state.products |> Enum.map(&Stream.Channels.order/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :depth}, state) do
    args = state.products |> Enum.map(&Stream.Channels.depth/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :trades}, state) do
    args = state.products |> Enum.map(&Stream.Channels.trade/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info(:heartbeat, state) do
    state = state |> schedule_heartbeat_timeout()
    {:reply, :ping, state}
  end

  def handle_info(:heartbeat_timeout, state) do
    {:close, {1000, "heartbeat timeout"}, state}
  end

  def handle_pong(:pong, state) do
    state =
      state
      |> cancel_heartbeat_timeout()
      |> schedule_heartbeat()

    {:ok, state}
  end

  def handle_frame({:binary, <<43, 200, 207, 75, 7, 0>> = pong}, state) do
    pong
    |> :zlib.unzip()
    |> handle_msg(state)
  end

  def handle_frame({:binary, compressed_data}, state) do
    compressed_data
    |> :zlib.unzip()
    |> Jason.decode!()
    |> handle_msg(state)
  end

  def handle_frame({:text, _}, state), do: {:ok, state}

  @heartbeat_ms 5_000
  defp schedule_heartbeat(state) do
    timer = Process.send_after(self(), :heartbeat, @heartbeat_ms)
    %{state | heartbeat_timer: timer}
  end

  @heartbeat_timeout_ms 3_000
  defp schedule_heartbeat_timeout(state) do
    timer = Process.send_after(self(), :heartbeat_timeout, @heartbeat_timeout_ms)
    %{state | heartbeat_timeout_timer: timer}
  end

  defp cancel_heartbeat_timeout(state) do
    Process.cancel_timer(state.heartbeat_timeout_timer)
    %{state | heartbeat_timeout_timer: nil}
  end

  defp handle_msg(
         %{"event" => "login", "success" => true},
         %State{credential: {credential_id, _}} = state
       ) do
    TaiEvents.info(%Tai.Events.StreamAuthOk{venue: state.venue, credential: credential_id})
    send(self(), {:subscribe, :orders})
    {:ok, state}
  end

  @product_types ~w(futures swap spot)
  @depth_tables @product_types |> Enum.map(&"#{&1}/depth")
  @order_tables @product_types |> Enum.map(&"#{&1}/order")

  defp handle_msg(%{"table" => table} = msg, state) when table in @depth_tables do
    msg |> forward(:order_books, state)
    {:ok, state}
  end

  defp handle_msg(%{"table" => table} = msg, state) when table in @order_tables do
    msg |> forward(:auth, state)
    {:ok, state}
  end

  defp handle_msg(msg, state) do
    msg |> forward(:optional_channels, state)
    {:ok, state}
  end

  defp forward(msg, to, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, System.monotonic_time()})
  end
end
