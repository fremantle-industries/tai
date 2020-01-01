defmodule Tai.VenueAdapters.Gdax.Stream.Connection do
  use WebSockex
  alias Tai.VenueAdapters.Gdax.Stream
  alias Tai.Events

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
            account: {account_id, map} | nil,
            products: [product],
            opts: map
          }

    @enforce_keys ~w(venue routes channels products opts)a
    defstruct ~w(venue routes channels account products opts)a
  end

  @type product :: Tai.Venues.Product.t()
  @type venue_id :: Tai.Venue.id()
  @type account_id :: Tai.Venue.account_id()
  @type account :: Tai.Venue.account()
  @type venue_msg :: map

  @spec start_link(
          url: String.t(),
          venue: venue_id,
          account: {account_id, account} | nil,
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
    routes = %{
      order_books: venue |> Stream.RouteOrderBooks.to_name(),
      optional_channels: venue |> Stream.ProcessOptionalChannels.to_name()
    }

    state = %State{
      venue: venue,
      routes: routes,
      channels: channels,
      account: account,
      products: products,
      opts: opts
    }

    name = venue |> to_name
    WebSockex.start_link(url, __MODULE__, state, name: name)
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

  def handle_info(:init_subscriptions, state) do
    send(self(), {:subscribe, :level2})

    {:ok, state}
  end

  def handle_info({:subscribe, :level2}, state) do
    product_ids = state.products |> Enum.map(& &1.venue_symbol)

    msg =
      %{"type" => "subscribe", "channels" => ["level2"], "product_ids" => product_ids}
      |> Jason.encode!()

    send(self(), {:send_msg, msg})

    {:ok, state}
  end

  def handle_info({:send_msg, msg}, state), do: {:reply, {:text, msg}, state}

  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state)

    {:ok, state}
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @order_book_msg_types ~w(l2update snapshot)
  defp handle_msg(%{"type" => type} = msg, state) when type in @order_book_msg_types do
    msg |> forward(:order_books, state)
  end

  defp handle_msg(msg, state) do
    msg |> forward(:optional_channels, state)
  end

  defp forward(msg, to, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, Timex.now()})
  end
end
