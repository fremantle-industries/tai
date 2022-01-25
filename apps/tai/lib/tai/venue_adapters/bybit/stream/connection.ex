defmodule Tai.VenueAdapters.Bybit.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter

  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.account()

  @spec start_link(
          endpoint: String.t(),
          stream: Tai.Venues.Stream.t(),
          credential: {credential_id, credential} | nil
        ) :: {:ok, pid}
  def start_link(endpoint: endpoint, stream: stream, credential: credential) do
    {name, state} = build_name_and_state(stream, credential)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  @impl true
  def subscribe(:init, state) do
    {:ok, state}
  end

  @impl true
  def subscribe({:depth, _product}, state) do
    {:noreply, state}
  end

  @impl true
  def on_msg(_msg, _received_at, state) do
    {:ok, state}
  end

  defp build_name_and_state(stream, credential) do
    name = process_name(stream.venue.id)

    state = %Tai.Venues.Streams.ConnectionAdapter.State{
      venue: stream.venue.id,
      routes: %{},
      channels: stream.venue.channels,
      credential: credential,
      markets: stream.markets,
      quote_depth: stream.venue.quote_depth,
      heartbeat_interval: stream.venue.stream_heartbeat_interval,
      heartbeat_timeout: stream.venue.stream_heartbeat_timeout,
      opts: stream.venue.opts
    }

    {name, state}
  end
end
