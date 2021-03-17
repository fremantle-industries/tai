defmodule Tai.VenueAdapters.OkEx.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.OkEx.Stream

  @type stream :: Tai.Venues.Stream.t()
  @type endpoint :: String.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.account()

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

    state = %Tai.Venues.Streams.ConnectionAdapter.State{
      venue: stream.venue.id,
      routes: routes,
      channels: stream.venue.channels,
      credential: credential,
      products: stream.products,
      quote_depth: stream.venue.quote_depth,
      heartbeat_interval: stream.venue.stream_heartbeat_interval,
      heartbeat_timeout: stream.venue.stream_heartbeat_timeout,
      connect_total: 0,
      disconnect_total: 0,
      opts: stream.venue.opts
    }

    name = process_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  def on_connect(_conn, state) do
    send(self(), {:heartbeat, :start})
    send(self(), {:subscribe, :init})
    if state.credential, do: send(self(), :login)
    :ok
  end

  def handle_pong(:pong, state) do
    state =
      state
      |> cancel_heartbeat_timeout()
      |> schedule_heartbeat()

    {:ok, state}
  end

  def handle_info({:heartbeat, :start}, state) do
    {:ok, schedule_heartbeat(state)}
  end

  def handle_info({:heartbeat, :ping}, state) do
    {:reply, :ping, schedule_heartbeat_timeout(state)}
  end

  def handle_info({:heartbeat, :timeout}, state) do
    {:close, {1000, "heartbeat timeout"}, state}
  end

  @optional_channels [
    :trades
  ]
  def handle_info({:subscribe, :init}, state) do
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

    {:ok, state}
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

  def handle_info(:login, state) do
    args = Stream.Auth.args(state.credential)
    msg = %{op: "login", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  defp schedule_heartbeat(state) do
    timer = Process.send_after(self(), {:heartbeat, :ping}, state.heartbeat_interval)
    %{state | heartbeat_timer: timer}
  end

  defp schedule_heartbeat_timeout(state) do
    timer = Process.send_after(self(), {:heartbeat, :timeout}, state.heartbeat_timeout)
    %{state | heartbeat_timeout_timer: timer}
  end

  defp cancel_heartbeat_timeout(state) do
    Process.cancel_timer(state.heartbeat_timeout_timer)
    %{state | heartbeat_timeout_timer: nil}
  end

  defp on_msg(
         %{"event" => "login", "success" => true},
         %_{credential: {credential_id, _}} = state
       ) do
    TaiEvents.info(%Tai.Events.StreamAuthOk{venue: state.venue, credential: credential_id})
    send(self(), {:subscribe, :orders})
    {:ok, state}
  end

  @product_types ~w(futures swap spot)
  @depth_tables @product_types |> Enum.map(&"#{&1}/depth")
  @order_tables @product_types |> Enum.map(&"#{&1}/order")

  defp on_msg(%{"table" => table} = msg, state) when table in @depth_tables do
    msg |> forward(:order_books, state)
    {:ok, state}
  end

  defp on_msg(%{"table" => table} = msg, state) when table in @order_tables do
    msg |> forward(:auth, state)
    {:ok, state}
  end

  defp on_msg(msg, state) do
    msg |> forward(:optional_channels, state)
    {:ok, state}
  end

  defp forward(msg, to, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, System.monotonic_time()})
  end
end
