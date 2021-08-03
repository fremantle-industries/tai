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
      order_books: stream.order_books,
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

    snapshot_order_books(stream.order_books, snapshot_depth)
    {:ok, pid}
  end

  @optional_channels [
    :trades
  ]
  @impl true
  def subscribe(:init, state) do
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

  @impl true
  def subscribe(:depth, state) do
    if Enum.any?(state.order_books) do
      channels =
        state.order_books
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
    else
      {:ok, state}
    end
  end

  @impl true
  def subscribe(:trades, state) do
    if Enum.any?(state.order_books) do
      channels =
        state.order_books
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
    else
      {:ok, state}
    end
  end

  @impl true
  def on_msg(%{"id" => id, "result" => nil}, _received_at_, state) do
    requests = Map.delete(state.requests, id)
    state = %{state | requests: requests}
    {:ok, state}
  end

  @impl true
  def on_msg(%{"e" => "depthUpdate"} = msg, received_at_, state) do
    msg |> forward(:order_books, received_at_, state)
    {:ok, state}
  end

  @impl true
  def on_msg(msg, received_at_, state) do
    msg |> forward(:optional_channels, received_at_, state)
    {:ok, state}
  end

  defp snapshot_order_books(order_books, depth) do
    order_books
    |> Enum.map(fn product ->
      with {:ok, change_set} <- Stream.Snapshot.fetch(product, depth) do
        change_set |> Tai.Markets.OrderBook.replace()
      else
        {:error, reason} -> raise reason
      end
    end)
  end

  defp stream_symbols(order_books) do
    order_books
    |> Enum.map(& &1.venue_symbol)
    |> Enum.map(&String.downcase/1)
  end

  defp forward(msg, to, received_at, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, received_at})
  end
end
