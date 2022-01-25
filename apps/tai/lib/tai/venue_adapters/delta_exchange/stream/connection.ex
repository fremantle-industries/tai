defmodule Tai.VenueAdapters.DeltaExchange.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  require Logger
  alias Tai.VenueAdapters.DeltaExchange.Stream

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
      markets: stream.venue.id |> Stream.RouteOrderBooks.to_name(),
    }

    state = %Tai.Venues.Streams.ConnectionAdapter.State{
      venue: stream.venue.id,
      routes: routes,
      channels: stream.venue.channels,
      credential: credential,
      markets: stream.markets,
      quote_depth: stream.venue.quote_depth,
      heartbeat_interval: stream.venue.stream_heartbeat_interval,
      heartbeat_timeout: stream.venue.stream_heartbeat_timeout,
      opts: stream.venue.opts
    }

    name = process_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  @impl true
  def subscribe(:init, state) do
    send(self(), {:subscribe, :orderbook})
    {:ok, state}
  end

  @subscribe_request %{
    "type" => "subscribe",
    "payload" => %{}
  }
  @order_books_chunk_count 100
  @impl true
  def subscribe(:orderbook, state) do
    state.markets
    |> Enum.map(& &1.venue_symbol)
    |> Enum.chunk_every(@order_books_chunk_count)
    |> Enum.each(fn chunk_symbols ->
      payload = %{
        "channels" => [%{
          "name" => "l2_orderbook",
          "symbols" => chunk_symbols
        }]
      }
      msg = @subscribe_request |> Map.put("payload", payload)
      send(self(), {:send_msg, msg})
    end)

    {:ok, state}
  end

  @impl true
  def on_msg(%{"type" => "l2_orderbook"} = msg, received_at, state) do
    msg |> forward(:markets, received_at, state)
    {:ok, state}
  end

  @impl true
  def on_msg(%{"type" => "subscriptions"}, _received_at, state) do
    {:ok, state}
  end

  @impl true
  def on_msg(%{"error" => %{"code" => code, "context" => context}}, _received_at, state) do
    case code do
      429 ->
        %{"limit_reset_in" => limit_reset_in} = context
        Logger.error "Too many requests limit_reset_in=#{limit_reset_in}"

      c ->
        Logger.warn "Unhandled error code=#{c}, context=#{inspect(context)}"
    end

    {:ok, state}
  end

  defp forward(msg, to, received_at, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, received_at})
  end
end
