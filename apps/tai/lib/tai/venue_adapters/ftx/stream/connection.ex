defmodule Tai.VenueAdapters.Ftx.Stream.Connection do
  use Tai.Venues.Streams.ConnectionAdapter
  alias Tai.VenueAdapters.Ftx.Stream

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
      markets: stream.venue.id |> Stream.RouteOrderBooks.process_name(),
      trades: stream.venue.id |> Stream.ProcessTrades.process_name(),
      optional_channels: stream.venue.id |> Stream.ProcessOptionalChannels.process_name()
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

  @optional_channels []
  @impl true
  def subscribe(:init, state) do
    if state.credential do
      send(self(), {:subscribe, :login})
      send(self(), {:subscribe, :orders})
    end

    send(self(), {:subscribe, :orderbook})
    send(self(), {:subscribe, :trades})

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
    {_credential_id, credentials} = state.credential
    credential = struct!(ExFtx.Credentials, credentials)
    api_key = credential.api_key
    api_secret = credential.api_secret
    ts = ExFtx.Auth.timestamp()
    signature = ExFtx.Auth.sign(api_secret, ts, "websocket_login", "", "")

    msg = %{
      "op" => "login",
      "args" => %{
        "key" => api_key,
        "sign" => signature,
        "time" => ts
      }
    }

    json_msg = msg |> Jason.encode!()

    {:reply, {:text, json_msg}, state}
  end

  @impl true
  def subscribe(:orders, state) do
    msg = %{"op" => "subscribe", "channel" => "orders"}
    json_msg = msg |> Jason.encode!()

    {:reply, {:text, json_msg}, state}
  end

  @subscribe_orderbook_request %{"op" => "subscribe", "channel" => "orderbook"}
  @impl true
  def subscribe(:orderbook, state) do
    state.markets
    |> Enum.each(fn p ->
      msg = @subscribe_orderbook_request |> Map.put("market", p.venue_symbol)
      send(self(), {:send_msg, msg})
    end)

    {:ok, state}
  end

  @subscribe_trades_request %{"op" => "subscribe", "channel" => "trades"}
  @impl true
  def subscribe(:trades, state) do
    state.markets
    |> Enum.each(fn p ->
      msg = @subscribe_trades_request |> Map.put("market", p.venue_symbol)
      send(self(), {:send_msg, msg})
    end)

    {:ok, state}
  end

  @impl true
  def on_msg(%{"channel" => "orderbook"} = msg, received_at, state) do
    msg |> forward(:markets, received_at, state)
    {:ok, state}
  end

  @impl true
  def on_msg(%{"channel" => "trades"} = msg, received_at, state) do
    msg |> forward(:trades, received_at, state)
    {:ok, state}
  end

  @impl true
  def on_msg(%{"channel" => "orders"} = msg, received_at, state) do
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
