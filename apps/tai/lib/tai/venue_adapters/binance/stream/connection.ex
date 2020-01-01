defmodule Tai.VenueAdapters.Binance.Stream.Connection do
  use WebSockex
  alias Tai.VenueAdapters.Binance.Stream

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type route :: :order_books | :optional_channels
    @type t :: %State{
            venue_id: venue_id,
            routes: %{required(route) => atom}
          }

    @enforce_keys ~w(venue_id routes)a
    defstruct ~w(venue_id routes)a
  end

  @type product :: Tai.Venues.Product.t()
  @type venue_id :: Tai.Venue.id()
  @type account_id :: Tai.Venue.account_id()
  @type account :: Tai.Venue.account()

  @spec start_link(
          url: String.t(),
          venue_id: venue_id,
          account: {account_id, account} | nil,
          products: [product]
        ) :: {:ok, pid}
  def start_link(url: url, venue_id: venue_id, account: _, products: products) do
    routes = %{
      order_books: venue_id |> Stream.RouteOrderBooks.to_name(),
      optional_channels: venue_id |> Stream.ProcessOptionalChannels.to_name()
    }

    state = %State{venue_id: venue_id, routes: routes}
    name = :"#{__MODULE__}_#{venue_id}"

    {:ok, pid} = WebSockex.start_link(url, __MODULE__, state, name: name)
    snapshot_order_books(products)
    {:ok, pid}
  end

  def handle_connect(_conn, state) do
    Tai.Events.info(%Tai.Events.StreamConnect{venue: state.venue_id})
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Tai.Events.info(%Tai.Events.StreamDisconnect{
      venue: state.venue_id,
      reason: conn_status.reason
    })

    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state)

    {:ok, state}
  end

  def handle_frame(_frame, state), do: {:ok, state}

  @price_levels 5
  defp snapshot_order_books(products) do
    products
    |> Enum.map(fn product ->
      with {:ok, change_set} <- Stream.Snapshot.fetch(product, @price_levels) do
        change_set |> Tai.Markets.OrderBook.replace()
      else
        {:error, reason} -> raise reason
      end
    end)
  end

  defp handle_msg(%{"data" => %{"e" => "depthUpdate"}} = msg, state) do
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
