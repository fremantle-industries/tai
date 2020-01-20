defmodule Tai.VenueAdapters.Deribit.Stream.Connection do
  use WebSockex
  alias Tai.{Events, VenueAdapters.Deribit.Stream}

  defmodule State do
    @type product :: Tai.Venues.Product.t()
    @type venue :: Tai.Venue.id()
    @type credential_id :: Tai.Venue.credential_id()
    @type channel_name :: atom
    # @type route :: :auth | :order_books | :optional_channels
    @type route :: :order_books
    @type t :: %State{
            venue: venue,
            routes: %{required(route) => atom},
            channels: [channel_name],
            credential: {credential_id, map} | nil,
            products: [product],
            quote_depth: pos_integer,
            opts: map
          }

    @enforce_keys ~w(venue routes channels products quote_depth opts)a
    defstruct ~w(venue routes channels credential products quote_depth opts)a
  end

  @type product :: Tai.Venues.Product.t()
  @type venue :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()
  @type venue_msg :: map

  @spec start_link(
          url: String.t(),
          venue: venue,
          credential: {credential_id, credential} | nil,
          products: [product],
          quote_depth: pos_integer,
          opts: map
        ) :: {:ok, pid} | {:error, term}
  def start_link(
        url: url,
        venue: venue,
        channels: channels,
        credential: credential,
        products: products,
        quote_depth: quote_depth,
        opts: opts
      ) do
    routes = %{
      order_books: venue |> Stream.RouteOrderBooks.to_name()
    }

    state = %State{
      venue: venue,
      routes: routes,
      channels: channels,
      credential: credential,
      products: products,
      quote_depth: quote_depth,
      opts: opts
    }

    name = venue |> to_name
    headers = []
    WebSockex.start_link(url, __MODULE__, state, name: name, extra_headers: headers)
  end

  @spec to_name(venue) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

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
    send(self(), {:subscribe, :depth})
    {:ok, state}
  end

  def handle_info({:subscribe, :depth}, state) do
    channels = state.products |> Enum.map(&"book.#{&1.venue_symbol}.none.20.100ms")

    msg =
      %{
        "method" => "public/subscribe",
        "params" => %{"channels" => channels}
      }
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

  def handle_frame(_frame, state), do: {:ok, state}

  defp handle_msg(%{"result" => _result}, _state), do: nil

  defp handle_msg(
         %{
           "method" => "subscription",
           "params" => %{"channel" => "book." <> _channel}
         } = msg,
         state
       ) do
    msg |> forward(:order_books, state)
  end

  defp forward(msg, to, state) do
    state.routes
    |> Map.fetch!(to)
    |> GenServer.cast({msg, Timex.now()})
  end
end
