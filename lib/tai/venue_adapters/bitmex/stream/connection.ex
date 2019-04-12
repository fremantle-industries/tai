defmodule Tai.VenueAdapters.Bitmex.Stream.Connection do
  use WebSockex
  require Logger

  @type product :: Tai.Venues.Product.t()
  @type t :: %Tai.VenueAdapters.Bitmex.Stream.Connection{
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
  def start_link(url: url, venue_id: venue_id, account: nil, products: products) do
    conn = %Tai.VenueAdapters.Bitmex.Stream.Connection{venue_id: venue_id}
    {:ok, pid} = WebSockex.start_link(url, __MODULE__, conn, name: :"#{__MODULE__}_#{venue_id}")
    subscribe_shared(pid, products)
    {:ok, pid}
  end

  def start_link(
        url: url,
        venue_id: venue_id,
        account: {_account_id, %{api_key: api_key, api_secret: api_secret}},
        products: products
      ) do
    conn = %Tai.VenueAdapters.Bitmex.Stream.Connection{venue_id: venue_id}
    nonce = ExBitmex.Auth.nonce()
    api_signature = ExBitmex.Auth.sign(api_secret, "GET", "/realtime", nonce, "")

    {:ok, pid} =
      WebSockex.start_link(
        url,
        __MODULE__,
        conn,
        name: :"#{__MODULE__}_#{venue_id}",
        extra_headers: [
          "api-key": api_key,
          "api-signature": api_signature,
          "api-expires": nonce
        ]
      )

    subscribe_shared(pid, products)
    subscribe_auth(pid)
    {:ok, pid}
  end

  def handle_connect(_conn, state) do
    Tai.Events.broadcast(%Tai.Events.StreamConnect{venue: state.venue_id})
    {:ok, state}
  end

  def handle_disconnect(conn_status, state) do
    Tai.Events.broadcast(%Tai.Events.StreamDisconnect{
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

  @spec handle_msg(msg :: map, venue_id :: atom) :: no_return
  defp handle_msg(msg, venue_id)

  defp handle_msg(%{"limit" => %{"remaining" => remaining}, "version" => _}, venue_id) do
    Tai.Events.broadcast(%Tai.Events.BitmexStreamConnectionLimitDetails{
      venue_id: venue_id,
      remaining: remaining
    })
  end

  defp handle_msg(%{"request" => _, "subscribe" => _} = msg, venue_id) do
    venue_id |> process_order_books(msg)
  end

  defp handle_msg(%{"table" => "orderBookL2_25"} = msg, venue_id) do
    venue_id |> process_order_books(msg)
  end

  defp handle_msg(%{"table" => "position"} = msg, venue_id) do
    venue_id |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "wallet"} = msg, venue_id) do
    venue_id |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "margin"} = msg, venue_id) do
    venue_id |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "order"} = msg, venue_id) do
    venue_id |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "execution"} = msg, venue_id) do
    venue_id |> process_auth_messages(msg)
  end

  defp handle_msg(%{"table" => "transact"} = msg, venue_id) do
    venue_id |> process_auth_messages(msg)
  end

  defp handle_msg(msg, venue_id) do
    venue_id |> process_messages(msg)
  end

  defp process_order_books(venue_id, msg) do
    venue_id
    |> Tai.VenueAdapters.Bitmex.Stream.ProcessOrderBooks.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end

  defp process_auth_messages(venue_id, msg) do
    venue_id
    |> Tai.VenueAdapters.Bitmex.Stream.ProcessAuthMessages.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end

  defp process_messages(venue_id, msg) do
    venue_id
    |> Tai.VenueAdapters.Bitmex.Stream.ProcessMessages.to_name()
    |> GenServer.cast({msg, Timex.now()})
  end
end
