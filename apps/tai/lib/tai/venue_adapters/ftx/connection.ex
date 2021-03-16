defmodule Tai.VenueAdapters.Ftx.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.Ftx.Stream

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
            credential: {credential_id, map} | nil,
            products: [product],
            quote_depth: pos_integer,
            opts: map,
            heartbeat_interval: pos_integer,
            heartbeat_timeout: pos_integer,
            heartbeat_timer: reference | nil,
            heartbeat_timeout_timer: reference | nil
          }

    @enforce_keys ~w[
      venue
      routes
      channels
      products
      quote_depth
      heartbeat_interval
      heartbeat_timeout
      opts
    ]a
    defstruct ~w[
      venue
      routes
      channels
      credential
      products
      quote_depth
      heartbeat_interval
      heartbeat_timeout
      heartbeat_timer
      heartbeat_timeout_timer
      opts
    ]a
  end

  @type stream :: Tai.Venues.Stream.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()
  @type venue_msg :: map

  @spec start_link(
          endpoint: String.t(),
          stream: stream,
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid} | {:error, term}
  def start_link(endpoint: endpoint, stream: stream, credential: credential) do
    routes = %{
      order_books: stream.venue.id |> Stream.RouteOrderBooks.to_name(),
      optional_channels: stream.venue.id |> Stream.ProcessOptionalChannels.to_name()
    }

    state = %State{
      venue: stream.venue.id,
      routes: routes,
      channels: stream.venue.channels,
      credential: credential,
      products: stream.products,
      quote_depth: stream.venue.quote_depth,
      heartbeat_interval: stream.venue.stream_heartbeat_interval,
      heartbeat_timeout: stream.venue.stream_heartbeat_timeout,
      opts: stream.venue.opts
    }

    name = to_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  def on_connect(_conn, _state) do
    send(self(), :init_subscriptions)
    :ok
  end

  @optional_channels [
    :trades,
  ]
  def handle_info(:init_subscriptions, state) do
    send(self(), {:subscribe, :orderbook})

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

  @subscribe_orderbook_request %{"op" => "subscribe", "channel" => "orderbook"}
  def handle_info({:subscribe, :orderbook}, state) do
    state.products
    |> Enum.each(fn p ->
      msg = @subscribe_orderbook_request |> Map.put("market", p.venue_symbol)
      send(self(), {:send_msg, msg})
    end)

    {:ok, state}
  end

  def handle_info(:heartbeat, state) do
    state = state |> schedule_heartbeat_timeout()
    {:reply, :ping, state}
  end

  def handle_info(:heartbeat_timeout, state) do
    {:close, {1000, "heartbeat timeout"}, state}
  end

  def handle_info({:send_msg, msg}, state) do
    json_msg = Jason.encode!(msg)
    {:reply, {:text, json_msg}, state}
  end

  def handle_pong(:pong, state) do
    state =
      state
      |> cancel_heartbeat_timeout()
      |> schedule_heartbeat()

    {:ok, state}
  end

  def on_msg(%{"channel" => "orderbook"} = msg, state) do
    msg |> forward(:order_books, state)
  end

  def on_msg(msg, state) do
    msg |> forward(:optional_channels, state)
  end

  defp schedule_heartbeat(state) do
    timer = Process.send_after(self(), :heartbeat, state.heartbeat_interval)
    %{state | heartbeat_timer: timer}
  end

  defp schedule_heartbeat_timeout(state) do
    timer = Process.send_after(self(), :heartbeat_timeout, state.heartbeat_timeout)
    %{state | heartbeat_timeout_timer: timer}
  end

  defp cancel_heartbeat_timeout(state) do
    Process.cancel_timer(state.heartbeat_timeout_timer)
    %{state | heartbeat_timeout_timer: nil}
  end

  defp forward(msg, to, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, System.monotonic_time()})
  end
end
