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
            account: {account_id, map} | nil,
            products: [product]
          }

    @enforce_keys ~w(venue products)a
    defstruct ~w(venue account products)a
  end

  @type product :: Venues.Product.t()
  @type venue_id :: Venues.Adapter.venue_id()
  @type account_id :: Venues.Adapter.account_id()
  @type account_config :: map

  @spec start_link(
          url: String.t(),
          venue: venue_id,
          account: {account_id, account_config} | nil,
          products: [product]
        ) :: {:ok, pid}
  def start_link(url: url, venue: venue, account: nil, products: products) do
    conn = %State{venue: venue, products: products}
    name = venue |> to_name
    {:ok, pid} = WebSockex.start_link(url, __MODULE__, conn, name: name)
    subscribe_shared(pid, products)
    {:ok, pid}
  end

  def start_link(
        url: url,
        venue: venue,
        account: {_account_id, %{api_key: api_key, api_secret: api_secret}} = account,
        products: products
      ) do
    conn = %State{venue: venue, account: account, products: products}
    name = venue |> to_name
    nonce = ExBitmex.Auth.nonce()
    api_signature = ExBitmex.Auth.sign(api_secret, "GET", "/realtime", nonce, "")

    auth_headers = [
      "api-key": api_key,
      "api-signature": api_signature,
      "api-expires": nonce
    ]

    {:ok, pid} =
      WebSockex.start_link(url, __MODULE__, conn, name: name, extra_headers: auth_headers)

    subscribe_shared(pid, products)
    subscribe_auth(pid)
    {:ok, pid}
  end

  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  def handle_connect(_conn, state) do
    Events.info(%Events.StreamConnect{venue: state.venue})
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Events.info(%Events.StreamDisconnect{
      venue: state.venue,
      reason: conn_status.reason
    })

    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    msg
    |> Jason.decode!()
    |> handle_msg(state.venue)

    {:ok, state}
  end

  def handle_frame(_frame, state), do: {:ok, state}

  defp subscribe_shared(pid, products) do
    subscribe_order_books(pid, products)
    subscribe_trades(pid, products)
    subscribe_interesting(pid)
  end

  defp subscribe_order_books(pid, products) do
    args = Enum.map(products, fn p -> "orderBookL2_25:#{p.venue_symbol}" end)
    msg = %{"op" => "subscribe", "args" => args}
    Tai.WebSocket.send_json_msg(pid, msg)
  end

  defp subscribe_trades(pid, products) do
    args = Enum.map(products, fn p -> "trade:#{p.venue_symbol}" end)
    msg = %{"op" => "subscribe", "args" => args}
    Tai.WebSocket.send_json_msg(pid, msg)
  end

  defp subscribe_interesting(pid) do
    msg = %{
      "op" => "subscribe",
      "args" => [
        "connected",
        "liquidation",
        "publicNotifications"
        # NOTE:  These aren't required for now. It would be nice if the channels could be configured
        # "funding",
        # "insurance",
        # "settlement",
      ]
    }

    Tai.WebSocket.send_json_msg(pid, msg)
  end

  defp subscribe_auth(pid) do
    msg = %{
      "op" => "subscribe",
      "args" => [
        "order"
        # NOTE:  These aren't required for now. It would be nice if the channels could be configured
        # "execution",
        # "margin",
        # "position",
        # "transact",
        # "wallet"
      ]
    }

    Tai.WebSocket.send_json_msg(pid, msg)
  end

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
