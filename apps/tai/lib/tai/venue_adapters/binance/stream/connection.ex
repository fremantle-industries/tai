defmodule Tai.VenueAdapters.Binance.Stream.Connection do
  use WebSockex
  alias Tai.VenueAdapters.Binance.Stream

  defmodule State do
    @type product :: Tai.Venues.Product.t()
    @type venue_id :: Tai.Venue.id()
    @type channel :: Tai.Venue.channel()
    @type route :: :order_books | :optional_channels
    @type request_id :: non_neg_integer
    @type t :: %State{
            venue: venue_id,
            products: [product],
            channels: [channel],
            routes: %{required(route) => atom},
            request_id: request_id,
            requests: %{
              optional(request_id) => pos_integer
            },
            heartbeat_timer: reference | nil,
            heartbeat_timeout_timer: reference | nil
          }

    @enforce_keys ~w[venue products channels routes request_id requests]a
    defstruct ~w[venue products channels routes request_id requests heartbeat_timer heartbeat_timeout_timer]a
  end

  @type stream :: Tai.Venues.Stream.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()

  @default_snapshot_depth 50

  @spec start_link(
          endpoint: String.t(),
          stream: stream,
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid}
  def start_link(endpoint: endpoint, stream: stream, credential: _) do
    name = :"#{__MODULE__}_#{stream.venue.id}"
    snapshot_depth = Map.get(stream.venue.opts, :snapshot_depth, @default_snapshot_depth)

    routes = %{
      order_books: stream.venue.id |> Stream.RouteOrderBooks.to_name(),
      optional_channels: stream.venue.id |> Stream.ProcessOptionalChannels.to_name()
    }

    state = %State{
      venue: stream.venue.id,
      products: stream.products,
      channels: stream.venue.channels,
      routes: routes,
      request_id: 1,
      requests: %{}
    }

    {:ok, pid} = WebSockex.start_link(endpoint, __MODULE__, state, name: name)

    snapshot_order_books(stream.products, snapshot_depth)
    {:ok, pid}
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue) do
    :"#{__MODULE__}_#{venue}"
  end

  def handle_connect(_conn, state) do
    TaiEvents.info(%Tai.Events.StreamConnect{venue: state.venue})
    send(self(), :init_subscriptions)
    state = state |> schedule_heartbeat()
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    TaiEvents.warn(%Tai.Events.StreamDisconnect{venue: state.venue, reason: conn_status.reason})
    {:ok, state}
  end

  def terminate(close_reason, state) do
    TaiEvents.warn(%Tai.Events.StreamTerminate{venue: state.venue, reason: close_reason})
  end

  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state)
  end

  def handle_frame(_frame, state), do: {:ok, state}

  @optional_channels [
    :trades
  ]
  def handle_info(:init_subscriptions, state) do
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

  def handle_info({:subscribe, :depth}, state) do
    channels =
      state.products
      |> stream_symbols
      |> Enum.map(&"#{&1}@depth@100ms")

    msg =
      %{
        method: "SUBSCRIBE",
        id: state.request_id,
        params: channels
      }
      |> Jason.encode!()

    state = state |> add_request()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :trades}, state) do
    channels =
      state.products
      |> stream_symbols
      |> Enum.map(&"#{&1}@trade")

    msg =
      %{
        method: "SUBSCRIBE",
        id: state.request_id,
        params: channels
      }
      |> Jason.encode!()

    state = state |> add_request()
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

  @heartbeat_timer 5_000
  defp schedule_heartbeat(state) do
    timer = Process.send_after(self(), :heartbeat, @heartbeat_timer)
    %{state | heartbeat_timer: timer}
  end

  @heartbeat_timeout_timer 3_000
  defp schedule_heartbeat_timeout(state) do
    timer = Process.send_after(self(), :heartbeat_timeout, @heartbeat_timeout_timer)
    %{state | heartbeat_timeout_timer: timer}
  end

  defp cancel_heartbeat_timeout(state) do
    Process.cancel_timer(state.heartbeat_timeout_timer)
    %{state | heartbeat_timeout_timer: nil}
  end

  defp snapshot_order_books(products, depth) do
    products
    |> Enum.map(fn product ->
      with {:ok, change_set} <- Stream.Snapshot.fetch(product, depth) do
        change_set |> Tai.Markets.OrderBook.replace()
      else
        {:error, reason} -> raise reason
      end
    end)
  end

  defp stream_symbols(products) do
    products
    |> Enum.map(& &1.venue_symbol)
    |> Enum.map(&String.downcase/1)
  end

  defp add_request(state) do
    requests = Map.put(state.requests, state.request_id, System.monotonic_time())
    %{state | request_id: state.request_id + 1, requests: requests}
  end

  defp handle_msg(%{"id" => id, "result" => nil}, state) do
    requests = Map.delete(state.requests, id)
    state = %{state | requests: requests}
    {:ok, state}
  end

  defp handle_msg(%{"e" => "depthUpdate"} = msg, state) do
    msg |> forward(:order_books, state)
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
