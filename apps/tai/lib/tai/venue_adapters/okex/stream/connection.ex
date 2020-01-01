defmodule Tai.VenueAdapters.OkEx.Stream.Connection do
  use WebSockex
  alias Tai.{Events, VenueAdapters.OkEx.Stream}
  alias Tai.VenueAdapters.OkEx.Stream

  defmodule State do
    @type product :: Tai.Venues.Product.t()
    @type venue_id :: Tai.Venue.id()
    @type account_id :: Tai.Venue.account_id()
    @type channel_name :: atom
    @type route :: :auth | :order_books | :optional_channels
    @type t :: %State{
            venue: venue_id,
            routes: %{required(route) => atom},
            channels: [channel_name],
            account: {account_id, map},
            products: [product]
          }

    @enforce_keys ~w(venue routes channels account products)a
    defstruct ~w(venue routes channels account products)a
  end

  @type product :: Tai.Venues.Product.t()
  @type channel :: Tai.Venue.channel()
  @type endpoint :: String.t()
  @type venue_id :: Tai.Venue.id()
  @type account_id :: Tai.Venue.account_id()
  @type account :: Tai.Venue.account()
  @type msg :: map | String.t()
  @type state :: State.t()

  @spec start_link(
          endpoint: endpoint,
          venue: venue_id,
          channels: [channel],
          account: {account_id, account} | nil,
          products: [product]
        ) :: {:ok, pid}
  def start_link(
        endpoint: endpoint,
        venue: venue,
        channels: channels,
        account: account,
        products: products
      ) do
    routes = %{
      auth: venue |> Stream.ProcessAuth.to_name(),
      order_books: venue |> Stream.RouteOrderBooks.to_name(),
      optional_channels: venue |> Stream.ProcessOptionalChannels.to_name()
    }

    state = %State{
      venue: venue,
      routes: routes,
      channels: channels,
      account: account,
      products: products
    }

    name = venue |> to_name
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  def handle_connect(_conn, state) do
    Events.info(%Events.StreamConnect{venue: state.venue})
    send(self(), :init_subscriptions)
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Events.error(%Events.StreamDisconnect{
      venue: state.venue,
      reason: conn_status.reason
    })

    {:ok, state}
  end

  @optional_channels [:trades]
  def handle_info(:init_subscriptions, state) do
    schedule_heartbeat()
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
    args = Stream.Auth.args(state.account)
    msg = %{op: "login", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :orders}, state) do
    args = state.products |> Enum.map(&Stream.Channels.order/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :depth}, state) do
    args = state.products |> Enum.map(&Stream.Channels.depth/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :trades}, state) do
    args = state.products |> Enum.map(&Stream.Channels.trade/1)
    msg = %{op: "subscribe", args: args} |> Jason.encode!()
    {:reply, {:text, msg}, state}
  end

  @ping "ping"
  def handle_info(:heartbeat, state) do
    schedule_heartbeat()
    {:reply, {:text, @ping}, state}
  end

  def handle_frame({:binary, <<43, 200, 207, 75, 7, 0>> = pong}, state) do
    pong
    |> :zlib.unzip()
    |> handle_msg(state)
  end

  def handle_frame({:binary, compressed_data}, state) do
    compressed_data
    |> :zlib.unzip()
    |> Jason.decode!()
    |> handle_msg(state)
  end

  def handle_frame({:text, _}, state), do: {:ok, state}

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @heartbeat_ms 20_000
  defp schedule_heartbeat, do: Process.send_after(self(), :heartbeat, @heartbeat_ms)

  defp handle_msg(
         %{"event" => "login", "success" => true},
         %State{account: {account_id, _}} = state
       ) do
    Events.info(%Events.StreamAuthOk{venue: state.venue, account: account_id})
    send(self(), {:subscribe, :orders})
    {:ok, state}
  end

  @product_types ~w(futures swap spot)
  @depth_tables @product_types |> Enum.map(&"#{&1}/depth")
  @order_tables @product_types |> Enum.map(&"#{&1}/order")

  defp handle_msg(%{"table" => table} = msg, state) when table in @depth_tables do
    msg |> forward(:order_books, state)
    {:ok, state}
  end

  defp handle_msg(%{"table" => table} = msg, state) when table in @order_tables do
    msg |> forward(:auth, state)
    {:ok, state}
  end

  defp handle_msg(msg, state) do
    msg |> forward(:optional_channels, state)
    {:ok, state}
  end

  defp forward(msg, to, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, Timex.now()})
  end
end
