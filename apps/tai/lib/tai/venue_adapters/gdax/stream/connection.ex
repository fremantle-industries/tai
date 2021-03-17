defmodule Tai.VenueAdapters.Gdax.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.Gdax.Stream

  @type stream :: Tai.Venues.Stream.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()

  @spec start_link(
          endpoint: String.t(),
          stream: venue_id,
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid} | {:error, term}
  def start_link(endpoint: endpoint, stream: stream, credential: credential) do
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
      opts: stream.venue.opts
    }

    name = process_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  def subscribe(:init, state) do
    send(self(), {:subscribe, :level2})
    {:ok, state}
  end

  def subscribe(:level2, state) do
    product_ids = state.products |> Enum.map(& &1.venue_symbol)
    msg = %{"type" => "subscribe", "channels" => ["level2"], "product_ids" => product_ids}
    send(self(), {:send_msg, msg})
    {:ok, state}
  end

  @order_book_msg_types ~w(l2update snapshot)
  def on_msg(%{"type" => type} = msg, state) when type in @order_book_msg_types do
    msg |> forward(:order_books, state)
    {:ok, state}
  end

  def on_msg(msg, state) do
    msg |> forward(:optional_channels, state)
    {:ok, state}
  end

  defp forward(msg, to, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, System.monotonic_time()})
  end
end
