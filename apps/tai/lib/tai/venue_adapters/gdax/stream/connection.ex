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
      order_books: stream.order_books,
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
    send(self(), {:subscribe, :level2})
    {:ok, state}
  end

  @impl true
  def subscribe(:level2, state) do
    if Enum.any?(state.order_books) do
      product_ids = state.order_books |> Enum.map(& &1.venue_symbol)
      msg = %{
        "type" => "subscribe",
        "channels" => ["level2"],
        "product_ids" => product_ids
      }
      |> Jason.encode!()

      {:reply, {:text, msg}, state}
    else
      {:ok, state}
    end
  end

  @order_book_msg_types ~w(l2update snapshot)
  @impl true
  def on_msg(%{"type" => type} = msg, received_at, state) when type in @order_book_msg_types do
    msg |> forward(:order_books, received_at, state)
    {:ok, state}
  end

  @impl true
  def on_msg(msg, received_at, state) do
    msg |> forward(:optional_channels, received_at, state)
    {:ok, state}
  end

  defp forward(msg, to, received_at, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, received_at})
  end
end
