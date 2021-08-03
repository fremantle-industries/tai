defmodule Tai.VenueAdapters.Huobi.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.Huobi.Stream

  @type stream :: Tai.Venues.Stream.t()
  @type endpoint :: String.t()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.account()

  @spec start_link(
          endpoint: endpoint,
          stream: stream,
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid}
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
      compression: :gunzip,
      opts: stream.venue.opts,
      requests: %Tai.Venues.Streams.ConnectionAdapter.Requests{
        next_request_id: 1,
        pending_requests: %{}
      }
    }

    name = process_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  @impl true
  def subscribe(:init, state) do
    state.order_books |> Enum.each(&send(self(), {:subscribe, {:depth, &1}}))
    {:ok, state}
  end

  @impl true
  def subscribe({:depth, product}, state) do
    with {:ok, sub} <- Stream.Channels.market_depth(product) do
      msg =
        %{
          sub: sub,
          data_type: "incremental",
          id: Integer.to_string(state.requests.next_request_id)
        }
        |> Jason.encode!()

      state = add_request(state)
      {:reply, {:text, msg}, state}
    else
      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def on_msg(%{"ch" => "market." <> _} = msg, received_at, state) do
    msg |> forward(:order_books, received_at, state)
    {:ok, state}
  end

  @impl true
  def on_msg(%{"ping" => timestamp}, _received_at, state) do
    msg = Jason.encode!(%{"pong" => timestamp})
    {:reply, {:text, msg}, state}
  end

  @impl true
  def on_msg(%{"id" => id}, _received_at, state) do
    requests = Map.delete(state.requests, id)
    state = %{state | requests: requests}
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
