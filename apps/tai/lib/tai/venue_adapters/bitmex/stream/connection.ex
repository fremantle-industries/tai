defmodule Tai.VenueAdapters.Bitmex.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.Bitmex.Stream

  @type stream :: Tai.Venues.Stream.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()

  @spec start_link(
          endpoint: String.t(),
          stream: stream,
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid} | {:error, term}
  def start_link(endpoint: endpoint, stream: stream, credential: credential) do
    routes = %{
      auth: stream.venue.id |> Stream.ProcessAuth.process_name(),
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
      opts: stream.venue.opts
    }

    name = process_name(stream.venue.id)
    headers = auth_headers(state.credential)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name, extra_headers: headers)
  end

  @optional_channels [
    :trades,
    :connected_stats,
    :liquidations,
    :notifications,
    :funding,
    :insurance,
    :settlement
  ]
  @impl true
  def subscribe(:init, state) do
    if state.credential do
      send(self(), {:subscribe, :login})
      send(self(), {:subscribe, :margin})
      send(self(), {:subscribe, :positions})
    end

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

    schedule_autocancel(0)

    {:ok, state}
  end

  @impl true
  def subscribe(:login, state) do
    msg = %{"op" => "subscribe", "args" => ["order"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  # Bitmex has an unpublished limit to websocket message lengths.
  @order_books_chunk_count 10
  @impl true
  def subscribe(:depth, state) do
    # > 25 quotes are experimental. It has performance issues causing message queue back pressure
    order_book_table = if state.quote_depth <= 25, do: "orderBookL2_25", else: "orderBookL2"

    state.order_books
    |> Enum.chunk_every(@order_books_chunk_count)
    |> Enum.each(fn order_books ->
      args = order_books |> Enum.map(fn p -> "#{order_book_table}:#{p.venue_symbol}" end)
      msg = %{"op" => "subscribe", "args" => args}
      send(self(), {:send_msg, msg})
    end)

    {:ok, state}
  end

  @impl true
  def subscribe(:trades, state) do
    state.order_books
    |> Enum.chunk_every(@order_books_chunk_count)
    |> Enum.each(fn order_books ->
      args = order_books |> Enum.map(fn p -> "trade:#{p.venue_symbol}" end)
      msg = %{"op" => "subscribe", "args" => args}
      send(self(), {:send_msg, msg})
    end)

    {:ok, state}
  end

  @impl true
  def subscribe(:positions, state) do
    msg = %{"op" => "subscribe", "args" => ["position"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:margin, state) do
    msg = %{"op" => "subscribe", "args" => ["margin"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:connected_stats, state) do
    msg = %{"op" => "subscribe", "args" => ["connected"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:liquidations, state) do
    msg = %{"op" => "subscribe", "args" => ["liquidation"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:notifications, state) do
    msg = %{"op" => "subscribe", "args" => ["publicNotifications"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:funding, state) do
    msg = %{"op" => "subscribe", "args" => ["funding"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:insurance, state) do
    msg = %{"op" => "subscribe", "args" => ["insurance"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:settlement, state) do
    msg = %{"op" => "subscribe", "args" => ["settlement"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  # TODO: Figure out how to move this
  @impl true
  def handle_info(
        :ping_autocancel,
        %{
          opts: %{
            autocancel: %{ping_interval_ms: ping_interval_ms, cancel_after_ms: cancel_after_ms}
          }
        } = state
      )
      when ping_interval_ms > 0 and is_integer(ping_interval_ms) and
             cancel_after_ms > 0 and is_integer(cancel_after_ms) do
    schedule_autocancel(ping_interval_ms)
    msg = %{"op" => "cancelAllAfter", "args" => cancel_after_ms} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def handle_info(:ping_autocancel, state), do: {:ok, state}

  @impl true
  def on_msg(%{"limit" => %{"remaining" => remaining}, "version" => _}, _received_at, state) do
    TaiEvents.info(%Tai.Events.BitmexStreamConnectionLimitDetails{
      venue_id: state.venue,
      remaining: remaining
    })
    {:ok, state}
  end

  @impl true
  def on_msg(%{"request" => _, "subscribe" => _} = msg, received_at, state) do
    msg |> forward(:order_books, received_at, state)
    {:ok, state}
  end

  @order_book_tables ~w(orderBookL2 orderBookL2_25)
  @impl true
  def on_msg(%{"table" => table} = msg, received_at, state) when table in @order_book_tables do
    msg |> forward(:order_books, received_at, state)
    {:ok, state}
  end

  @auth_tables ~w(position wallet margin order execution transact)
  @impl true
  def on_msg(%{"table" => table} = msg, received_at, state) when table in @auth_tables do
    msg |> forward(:auth, received_at, state)
    {:ok, state}
  end

  @impl true
  def on_msg(msg, received_at, state) do
    msg |> forward(:optional_channels, received_at, state)
    {:ok, state}
  end

  defp auth_headers({_credential_id, %{api_key: api_key, api_secret: api_secret}}) do
    nonce = ExBitmex.Auth.nonce()
    api_signature = ExBitmex.Auth.sign(api_secret, "GET", "/realtime", nonce, "")

    [
      "api-key": api_key,
      "api-signature": api_signature,
      "api-expires": nonce
    ]
  end

  defp auth_headers(nil), do: []

  defp schedule_autocancel(after_ms) do
    Process.send_after(self(), :ping_autocancel, after_ms)
  end

  defp forward(msg, to, received_at, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, received_at})
  end
end
