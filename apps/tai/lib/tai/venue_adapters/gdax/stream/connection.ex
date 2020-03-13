defmodule Tai.VenueAdapters.Gdax.Stream.Connection do
  use WebSockex
  alias Tai.VenueAdapters.Gdax.Stream

  defmodule State do
    @type product :: Tai.Venues.Product.t()
    @type venue_id :: Tai.Venue.id()
    @type credential_id :: Tai.Venue.credential_id()
    @type channel_name :: atom
    @type route :: :auth | :order_books | :optional_channels
    @type t :: %State{
            venue: venue_id,
            routes: %{required(route) => atom},
            channels: [channel_name],
            credential: {credential_id, map} | nil,
            products: [product],
            opts: map
          }

    @enforce_keys ~w(venue routes channels products opts)a
    defstruct ~w(venue routes channels credential products opts)a
  end

  @type stream :: Tai.Venues.Stream.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()
  @type venue_msg :: map

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

    state = %State{
      venue: stream.venue.id,
      routes: routes,
      channels: stream.venue.channels,
      credential: credential,
      products: stream.products,
      opts: stream.venue.opts
    }

    name = to_name(stream.venue.id)
    WebSockex.start_link(endpoint, __MODULE__, state, name: name)
  end

  def terminate(close_reason, state) do
    TaiEvents.warn(%Tai.Events.StreamTerminate{venue: state.venue, reason: close_reason})
  end

  def handle_connect(_conn, state) do
    TaiEvents.info(%Tai.Events.StreamConnect{venue: state.venue})
    send(self(), :init_subscriptions)
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    TaiEvents.warn(%Tai.Events.StreamDisconnect{venue: state.venue, reason: conn_status.reason})
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
