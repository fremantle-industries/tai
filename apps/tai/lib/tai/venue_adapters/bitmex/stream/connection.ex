defmodule Tai.VenueAdapters.Bitmex.Stream.Connection do
  use WebSockex
  alias Tai.{Events, Venues, VenueAdapters.Bitmex.Stream}

  defmodule State do
    @type product :: Venues.Product.t()
    @type venue_id :: Venues.Adapter.venue_id()
    @type account_id :: Venues.Adapter.account_id()
    @type channel_name :: atom
    @type t :: %State{
            venue: venue_id,
            channels: [channel_name],
            account: {account_id, map} | nil,
            products: [product],
            opts: map
          }

    @enforce_keys ~w(venue channels products opts)a
    defstruct ~w(venue channels account products opts)a
  end

  @type product :: Venues.Product.t()
  @type venue_id :: Venues.Adapter.venue_id()
  @type account_id :: Venues.Adapter.account_id()
  @type account_config :: map

  @spec start_link(
          url: String.t(),
          venue: venue_id,
          account: {account_id, account_config} | nil,
          products: [product],
          opts: map
        ) :: {:ok, pid} | {:error, term}
  def start_link(
        url: url,
        venue: venue,
        channels: channels,
        account: account,
        products: products,
        opts: opts
      ) do
    state = %State{
      venue: venue,
      channels: channels,
      account: account,
      products: products,
      opts: opts
    }

    name = venue |> to_name
    headers = auth_headers(state.account)
    WebSockex.start_link(url, __MODULE__, state, name: name, extra_headers: headers)
  end

  def handle_connect(_conn, state) do
    Events.info(%Events.StreamConnect{venue: state.venue})
    send(self(), :init_subscriptions)
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Events.info(%Events.StreamDisconnect{
      venue: state.venue,
      reason: conn_status.reason
    })

    {:ok, state}
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
  def handle_info(:init_subscriptions, state) do
    schedule_heartbeat()
    schedule_autocancel(0)
    if state.account, do: send(self(), :login)
    send(self(), {:subscribe, :depth})

    state.channels
    |> Enum.each(fn c ->
      if Enum.member?(@optional_channels, c) do
        send(self(), {:subscribe, c})
      else
        Events.warn(%Events.StreamChannelInvalid{
          venue: state.venue,
          name: c,
          available: @optional_channels
        })
      end
    end)

    {:ok, state}
  end

  def handle_info(:login, state) do
    msg = %{"op" => "subscribe", "args" => ["order"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:send_msg, msg}, state), do: {:reply, {:text, msg}, state}

  # Bitmex has an unpublished limit to websocket message lengths.
  @products_chunk_count 10
  def handle_info({:subscribe, :depth}, state) do
    state.products
    |> Enum.chunk_every(@products_chunk_count)
    |> Enum.each(fn products ->
      args = products |> Enum.map(fn p -> "orderBookL2_25:#{p.venue_symbol}" end)
      msg = %{"op" => "subscribe", "args" => args} |> Jason.encode!()
      send(self(), {:send_msg, msg})
    end)

    {:ok, state}
  end

  def handle_info({:subscribe, :trades}, state) do
    state.products
    |> Enum.chunk_every(@products_chunk_count)
    |> Enum.each(fn products ->
      args = products |> Enum.map(fn p -> "trade:#{p.venue_symbol}" end)
      msg = %{"op" => "subscribe", "args" => args} |> Jason.encode!()
      send(self(), {:send_msg, msg})
    end)

    {:ok, state}
  end

  def handle_info({:subscribe, :connected_stats}, state) do
    msg = %{"op" => "subscribe", "args" => ["connected"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :liquidations}, state) do
    msg = %{"op" => "subscribe", "args" => ["liquidation"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :notifications}, state) do
    msg = %{"op" => "subscribe", "args" => ["publicNotifications"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :funding}, state) do
    msg = %{"op" => "subscribe", "args" => ["funding"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :insurance}, state) do
    msg = %{"op" => "subscribe", "args" => ["insurance"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :settlement}, state) do
    msg = %{"op" => "subscribe", "args" => ["settlement"]} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info(:heartbeat, state) do
    {:reply, :ping, state}
  end

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

  def handle_info(:ping_autocancel, state), do: {:ok, state}

  def handle_pong(:pong, state) do
    schedule_heartbeat()
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state.venue)

    {:ok, state}
  end

  def handle_frame(_frame, state), do: {:ok, state}

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  defp auth_headers({_account_id, %{api_key: api_key, api_secret: api_secret}}) do
    nonce = ExBitmex.Auth.nonce()
    api_signature = ExBitmex.Auth.sign(api_secret, "GET", "/realtime", nonce, "")

    [
      "api-key": api_key,
      "api-signature": api_signature,
      "api-expires": nonce
    ]
  end

  defp auth_headers(nil), do: []

  defp schedule_autocancel(after_ms),
    do: Process.send_after(self(), :ping_autocancel, after_ms)

  @heartbeat_ms 20_000
  defp schedule_heartbeat, do: Process.send_after(self(), :heartbeat, @heartbeat_ms)

  @spec handle_msg(msg :: map, venue_id) :: no_return
  defp handle_msg(msg, venue)

  defp handle_msg(%{"limit" => %{"remaining" => remaining}, "version" => _}, venue) do
    Events.info(%Events.BitmexStreamConnectionLimitDetails{
      venue_id: venue,
      remaining: remaining
    })
  end

  defp handle_msg(%{"request" => _, "subscribe" => _} = msg, venue) do
    venue |> process_order_books(msg)
  end

  defp handle_msg(%{"table" => "orderBookL2_25"} = msg, venue) do
    venue |> process_order_books(msg)
  end

  defp handle_msg(%{"table" => "position"} = msg, venue) do
    venue |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "wallet"} = msg, venue) do
    venue |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "margin"} = msg, venue) do
    venue |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "order"} = msg, venue) do
    venue |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "execution"} = msg, venue) do
    venue |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "transact"} = msg, venue) do
    venue |> process_auth_messages(msg)
  end

  defp handle_msg(msg, venue) do
    venue |> process_messages(msg)
  end

  defp process_order_books(venue, msg) do
    venue
    |> Stream.ProcessOrderBooks.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end

  defp process_auth_messages(venue, msg) do
    venue
    |> Stream.ProcessAuth.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end

  defp process_messages(venue, msg) do
    venue
    |> Stream.ProcessMessages.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end
end
