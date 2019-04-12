defmodule Tai.VenueAdapters.Binance.Stream.Connection do
  use WebSockex
  require Logger
  alias Tai.VenueAdapters.Binance.Stream

  @type product :: Tai.Venues.Product.t()
  @type t :: %Tai.VenueAdapters.Binance.Stream.Connection{
          venue_id: atom
        }

  @enforce_keys [:venue_id]
  defstruct [:venue_id]

  @spec start_link(
          url: String.t(),
          venue_id: atom,
          account: {account_id :: atom, account_config :: map} | nil,
          products: [product]
        ) :: {:ok, pid}
  def start_link(url: url, venue_id: venue_id, account: _, products: products) do
    conn = %Tai.VenueAdapters.Binance.Stream.Connection{venue_id: venue_id}
    {:ok, pid} = WebSockex.start_link(url, __MODULE__, conn, name: :"#{__MODULE__}_#{venue_id}")
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
    Logger.debug(fn -> "Received raw msg: #{msg}" end)

    msg
    |> Jason.decode!()
    |> handle_msg(state.venue_id)

    {:ok, state}
  end

  def handle_frame(_frame, state), do: {:ok, state}

  @price_levels 5
  defp snapshot_order_books(products) do
    products
    |> Enum.map(fn product ->
      with {:ok, snapshot} <- Stream.Snapshot.fetch(product, @price_levels) do
        :ok = Tai.Markets.OrderBook.replace(snapshot)
      else
        {:error, reason} -> raise reason
      end
    end)
  end

  @spec handle_msg(msg :: map, venue_id :: atom) :: no_return
  defp handle_msg(msg, venue_id)

  defp handle_msg(%{"data" => %{"e" => "depthUpdate"}} = msg, venue_id) do
    venue_id |> process_order_books(msg)
  end

  defp handle_msg(msg, venue_id) do
    venue_id |> process_messages(msg)
  end

  defp process_order_books(venue_id, msg) do
    venue_id
    |> Tai.VenueAdapters.Binance.Stream.ProcessOrderBooks.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end

  defp process_messages(venue_id, msg) do
    venue_id
    |> Tai.VenueAdapters.Binance.Stream.ProcessMessages.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end
end
