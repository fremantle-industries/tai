defmodule Tai.VenueAdapters.Binance.Stream.Connection do
  use WebSockex
  alias Tai.VenueAdapters.Binance.Stream
  alias Tai.Events

  defmodule State do
    @type product :: Tai.Venues.Product.t()
    @type venue_id :: Tai.Venue.id()
    @type channel :: Tai.Venue.channel()
    @type route :: :order_books | :optional_channels
    @type request_id :: non_neg_integer
    @type t :: %State{
            venue_id: venue_id,
            products: [product],
            channels: [channel],
            routes: %{required(route) => atom},
            request_id: request_id,
            requests: %{
              optional(request_id) => pos_integer
            }
          }

    @enforce_keys ~w(venue_id products channels routes request_id requests)a
    defstruct ~w(venue_id products channels routes request_id requests)a
  end

  @type product :: Tai.Venues.Product.t()
  @type venue_id :: Tai.Venue.id()
  @type channel :: Tai.Venue.channel()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()

  @default_snapshot_depth 50

  @spec start_link(
          url: String.t(),
          venue: venue_id,
          channels: [channel],
          credential: {credential_id, credential} | nil,
          products: [product],
          opts: map
        ) :: {:ok, pid}
  def start_link(
        url: url,
        venue: venue,
        channels: channels,
        credential: _,
        products: products,
        opts: opts
      ) do
    name = :"#{__MODULE__}_#{venue}"
    snapshot_depth = Map.get(opts, :snapshot_depth, @default_snapshot_depth)

    routes = %{
      order_books: venue |> Stream.RouteOrderBooks.to_name(),
      optional_channels: venue |> Stream.ProcessOptionalChannels.to_name()
    }

    state = %State{
      venue_id: venue,
      products: products,
      channels: channels,
      routes: routes,
      request_id: 1,
      requests: %{}
    }

    {:ok, pid} = WebSockex.start_link(url, __MODULE__, state, name: name)

    snapshot_order_books(products, snapshot_depth)
    {:ok, pid}
  end

  def handle_connect(_conn, state) do
    Events.info(%Events.StreamConnect{venue: state.venue_id})
    send(self(), :init_subscriptions)
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Events.info(%Events.StreamDisconnect{venue: state.venue_id, reason: conn_status.reason})
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state)
  end

  def handle_frame(_frame, state), do: {:ok, state}

  @optional_channels [
    :trades
  ]
  def handle_info(:init_subscriptions, state) do
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

  def handle_info({:subscribe, :depth}, state) do
    channels =
      state.products
      |> stream_symbols
      |> Enum.map(&"#{&1}@depth@100ms")

    msg =
      %{
        method: "SUBSCRIBE",
        id: state.request_id,
        params: channels
      }
      |> Jason.encode!()

    state = state |> add_request()
    {:reply, {:text, msg}, state}
  end

  def handle_info({:subscribe, :trades}, state) do
    channels =
      state.products
      |> stream_symbols
      |> Enum.map(&"#{&1}@trade")

    msg =
      %{
        method: "SUBSCRIBE",
        id: state.request_id,
        params: channels
      }
      |> Jason.encode!()

    state = state |> add_request()
    {:reply, {:text, msg}, state}
  end

  defp snapshot_order_books(products, depth) do
    products
    |> Enum.map(fn product ->
      with {:ok, change_set} <- Stream.Snapshot.fetch(product, depth) do
        change_set |> Tai.Markets.OrderBook.replace()
      else
        {:error, reason} -> raise reason
      end
    end)
  end

  defp stream_symbols(products) do
    products
    |> Enum.map(& &1.venue_symbol)
    |> Enum.map(&String.downcase/1)
  end

  defp add_request(state) do
    requests = Map.put(state.requests, state.request_id, :os.system_time(:millisecond))
    %{state | request_id: state.request_id + 1, requests: requests}
  end

  defp handle_msg(%{"id" => id, "result" => nil}, state) do
    requests = Map.delete(state.requests, id)
    state = %{state | requests: requests}
    {:ok, state}
  end

  defp handle_msg(%{"e" => "depthUpdate"} = msg, state) do
    msg |> forward(:order_books, state)
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
