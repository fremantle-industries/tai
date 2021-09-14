defmodule Tai.VenueAdapters.OkEx.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.OkEx.Stream

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
      auth: stream.venue.id |> Stream.ProcessAuth.process_name(),
      markets: stream.venue.id |> Stream.RouteOrderBooks.to_name(),
      optional_channels: stream.venue.id |> Stream.ProcessOptionalChannels.to_name()
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
      compression: :unzip,
      opts: stream.venue.opts
    }

    name = process_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  @optional_channels [
    :trades
  ]
  @impl true
  def subscribe(:init, state) do
    if state.credential, do: send(self(), {:subscribe, :login})

    send(self(), {:subscribe, :depth})

    state.channels
    |> Enum.each(fn c ->
      if Enum.member?(@optional_channels, c) do
        send(self(), {:subscribe, c})
      else
        TaiEvents.warning(%Tai.Events.StreamChannelInvalid{
          venue: state.venue,
          name: c,
          available: @optional_channels
        })
      end
    end)

    {:ok, state}
  end

  @impl true
  def subscribe(:login, state) do
    args = Stream.Auth.args(state.credential)
    msg = %{op: "login", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:orders, state) do
    args = state.markets |> Enum.map(&Stream.Channels.order/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:depth, state) do
    args = state.markets |> Enum.map(&Stream.Channels.depth/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def subscribe(:trades, state) do
    args = state.markets |> Enum.map(&Stream.Channels.trade/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @impl true
  def on_msg(
    %{"event" => "login", "success" => true},
    _received_at,
    %_{credential: {credential_id, _}} = state
  ) do
    TaiEvents.info(%Tai.Events.StreamAuthOk{
      venue: state.venue,
      credential: credential_id
    })
    send(self(), {:subscribe, :orders})
    {:ok, state}
  end

  @product_types ~w(futures swap spot)
  @depth_tables @product_types |> Enum.map(&"#{&1}/depth")
  @order_tables @product_types |> Enum.map(&"#{&1}/order")

  @impl true
  def on_msg(%{"table" => table} = msg, received_at, state) when table in @depth_tables do
    msg |> forward(:markets, received_at, state)
    {:ok, state}
  end

  @impl true
  def on_msg(%{"table" => table} = msg, received_at, state) when table in @order_tables do
    msg |> forward(:auth, received_at, state)
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
