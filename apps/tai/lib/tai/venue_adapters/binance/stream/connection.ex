defmodule Tai.VenueAdapters.Binance.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.Binance.Stream

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
  def start_link(endpoint: endpoint, stream: stream, credential: credential) do
    snapshot_depth = Map.get(stream.venue.opts, :snapshot_depth, @default_snapshot_depth)

    routes = %{
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
      opts: stream.venue.opts,
      requests: %Tai.Venues.Streams.ConnectionAdapter.Requests{
        next_request_id: 1,
        pending_requests: %{}
      }
    }

    name = stream.venue.id |> process_name()
    {:ok, pid} = WebSockex.start_link(endpoint, __MODULE__, state, name: name)

    snapshot_order_books(stream.products, snapshot_depth)
    {:ok, pid}
  end

  def on_connect(_conn, _state) do
    send(self(), {:heartbeat, :start})
    send(self(), {:subscribe, :init})
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
    state = state |> schedule_heartbeat_timeout()
    {:reply, :ping, state}
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

  def handle_info({:subscribe, :depth}, state) do
    channels =
      state.products
      |> stream_symbols
      |> Enum.map(&"#{&1}@depth@100ms")

    msg =
      %{
        method: "SUBSCRIBE",
        id: state.requests.next_request_id,
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
        id: state.requests.next_request_id,
        params: channels
      }
      |> Jason.encode!()

    state = state |> add_request()
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
    pending_requests = Map.put(state.requests, state.requests.next_request_id, System.monotonic_time())
    requests = %{state.requests | next_request_id: state.requests.next_request_id + 1, pending_requests: pending_requests}
    %{state | requests: requests}
  end

  defp on_msg(%{"id" => id, "result" => nil}, state) do
    requests = Map.delete(state.requests, id)
    state = %{state | requests: requests}
    {:ok, state}
  end

  defp on_msg(%{"e" => "depthUpdate"} = msg, state) do
    msg |> forward(:order_books, state)
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
