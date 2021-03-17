defmodule Tai.VenueAdapters.Huobi.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.Huobi.Stream

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

  def subscribe(:init, state) do
    state.products |> Enum.each(&send(self(), {:subscribe, {:depth, &1}}))
    {:ok, state}
  end

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

  def on_msg(%{"ch" => "market." <> _} = msg, state) do
    msg |> forward(:order_books, state)
    {:ok, state}
  end

  def on_msg(%{"ping" => timestamp}, state) do
    msg = Jason.encode!(%{"pong" => timestamp})
    {:reply, {:text, msg}, state}
  end

  def on_msg(%{"id" => id}, state) do
    requests = Map.delete(state.requests, id)
    state = %{state | requests: requests}
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
