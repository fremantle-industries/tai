defmodule Tai.ExchangeAdapters.Poloniex.OrderBookFeed do
  @moduledoc """
  """

  use Tai.Exchanges.OrderBookFeed

  alias Tai.{Exchanges.OrderBookFeed, Markets.OrderBook, WebSocket}
  alias Tai.ExchangeAdapters.Poloniex.{Snapshot, SymbolMapping}

  @doc """
  Secure production Poloniex WebSocket url.

  This is the undocumented API used by the website. The "official" documented 
  Push API does not work.
  """
  def default_url, do: "wss://api2.poloniex.com/"

  def subscribe_to_order_books(pid, _feed_id, symbols) do
    results =
      symbols
      |> Enum.map(fn symbol ->
        with poloniex_symbol <- SymbolMapping.to_poloniex(symbol),
             :ok <-
               WebSocket.send_json_msg(pid, %{command: "subscribe", channel: poloniex_symbol}) do
          :ok
        else
          {:error, _} = error ->
            error
        end
      end)

    errors = Enum.reject(results, &(&1 == :ok))

    if Enum.any?(errors) do
      message = subscribe_error_message(errors)
      Logger.warn(message)
      {:error, message}
    else
      :ok
    end
  end

  defp subscribe_error_message(errors) do
    errors
    |> Enum.map(fn {:error, reason} ->
      reason
      |> List.wrap()
      |> Enum.join(" ")
    end)
    |> Enum.join(", ")
  end

  @doc """
  Heartbeat

  In some markets, if there is no update for more than 1 second, a heartbeat 
  message consisting of an empty argument list and the latest sequence number 
  will be sent. These will go out once per second, but if there is no update 
  for more than 60 seconds, the heartbeat interval will be reduced to 8 seconds 
  until the next update.
  """
  def handle_msg([1010], state) do
    Logger.debug(fn -> "heartbeat" end)
    {:ok, state}
  end

  @doc """
  Process the list of events for the channel. It ignores events not listed below

  i - Apply snapshot initialization immediately and save the channel/symbol mapping
  o - Group the order book changes together and apply as a batch
  """
  def handle_msg(
        [
          channel_id,
          _sequence_id,
          events
        ],
        %OrderBookFeed{} = state
      ) do
    new_state =
      state
      |> init_snapshot(channel_id, events)
      |> update_order_books(channel_id, events)

    {:ok, new_state}
  end

  @doc """
  Log a warning message when the WebSocket receives a message that is not explicitly handled
  """
  def handle_msg(unhandled_msg, state) do
    Logger.warn("unhandled message: #{inspect(unhandled_msg)}")

    {:ok, state}
  end

  defp init_snapshot(state, channel_id, [
         ["i", %{"currencyPair" => currency_pair, "orderBook" => [asks, bids]}] | _tail
       ]) do
    processed_at = Timex.now()
    symbol = currency_pair |> SymbolMapping.to_tai()

    snapshot = %OrderBook{
      bids: bids |> Snapshot.normalize(processed_at),
      asks: asks |> Snapshot.normalize(processed_at)
    }

    [feed_id: state.feed_id, symbol: symbol]
    |> OrderBook.to_name()
    |> OrderBook.replace(snapshot)

    new_store = state.store |> Map.put(channel_id, symbol)
    state |> Map.put(:store, new_store)
  end

  defp init_snapshot(state, _channel_id, _events), do: state

  defp update_order_books(state, channel_id, events) do
    state
    |> update_order_books(channel_id, events, %{}, %{})
  end

  defp update_order_books(state, channel_id, [], bids, asks) do
    unless Enum.empty?(bids) && Enum.empty?(asks) do
      processed_at = Timex.now()
      symbol = state.store |> Map.get(channel_id)

      changes = %OrderBook{
        bids: bids |> Snapshot.normalize(processed_at),
        asks: asks |> Snapshot.normalize(processed_at)
      }

      [feed_id: state.feed_id, symbol: symbol]
      |> OrderBook.to_name()
      |> OrderBook.update(changes)
    end

    state
  end

  defp update_order_books(
         state,
         channel_id,
         [["o", side, price, size] | tail],
         bids,
         asks
       ) do
    {new_bids, new_asks} =
      case side do
        1 -> {bids |> Map.put(price, size), asks}
        0 -> {bids, asks |> Map.put(price, size)}
      end

    state
    |> update_order_books(channel_id, tail, new_bids, new_asks)
  end

  defp update_order_books(
         state,
         channel_id,
         [_ | tail],
         bids,
         asks
       ) do
    state
    |> update_order_books(channel_id, tail, bids, asks)
  end
end
