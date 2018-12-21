defmodule Tai.VenueAdapters.Binance.OrderBookFeed do
  @moduledoc """
  WebSocket order book feed adapter for Binance

  https://github.com/binance-exchange/binance-official-api-docs/blob/master/web-socket-streams.md
  """

  use Tai.Venues.OrderBookFeed
  alias Tai.VenueAdapters.Binance.OrderBookFeed
  require Logger

  @doc """
  Secure production Binance WebSocket url
  """
  def default_url, do: "wss://stream.binance.com:9443/stream"

  @doc """
  Subscribe to streams for all symbols
  """
  @spec build_connection_url(String.t(), [atom, ...]) :: String.t()
  def build_connection_url(url, symbols) do
    streams =
      symbols
      |> Enum.map(&Tai.ExchangeAdapters.Binance.SymbolMapping.to_binance/1)
      |> Enum.map(&String.downcase/1)
      |> Enum.map(&"#{&1}@depth")
      |> Enum.join("/")

    "#{url}?streams=#{streams}"
  end

  @doc """
  Snapshot the order book 5 levels deep
  """
  @price_levels 5
  @spec subscribe_to_order_books(pid, atom, list) :: :ok | {:error, bitstring}
  def subscribe_to_order_books(_pid, feed_id, symbols) do
    subscriptions =
      symbols
      |> Enum.map(fn symbol ->
        with {:ok, %Tai.Markets.OrderBook{} = snapshot} <-
               OrderBookFeed.Snapshot.fetch(feed_id, symbol, @price_levels) do
          :ok = Tai.Markets.OrderBook.replace(snapshot)
          :ok
        else
          {:error, :invalid_symbol} ->
            {:error, symbol}
        end
      end)

    errors = Enum.reject(subscriptions, &(&1 == :ok))

    if Enum.any?(errors) do
      message = subscribe_error_message(errors)
      Logger.warn(message)
      {:error, message}
    else
      :ok
    end
  end

  defp subscribe_error_message(errors) do
    symbols =
      errors
      |> Enum.map(fn {:error, symbol} ->
        symbol
        |> List.wrap()
        |> Enum.join(" ")
      end)
      |> Enum.join(", ")

    "could not subscribe to order books with invalid symbols: #{symbols}"
  end

  @doc """
  Update the order book as changes are received
  """
  def handle_msg(
        %{
          "data" => %{
            "e" => "depthUpdate",
            "E" => event_time,
            "s" => binance_symbol,
            "U" => _first_update_id_in_event,
            "u" => _final_update_id_in_event,
            "b" => changed_bids,
            "a" => changed_asks
          },
          "stream" => _stream_name
        },
        state
      ) do
    processed_at = Timex.now()
    {:ok, server_changed_at} = DateTime.from_unix(event_time, :millisecond)
    symbol = Tai.ExchangeAdapters.Binance.SymbolMapping.to_tai(binance_symbol)

    bids = changed_bids |> OrderBookFeed.DepthUpdate.normalize(processed_at, server_changed_at)
    asks = changed_asks |> OrderBookFeed.DepthUpdate.normalize(processed_at, server_changed_at)

    normalized_changes = %Tai.Markets.OrderBook{
      venue_id: state.feed_id,
      product_symbol: symbol,
      bids: bids,
      asks: asks
    }

    state.feed_id
    |> Tai.Markets.OrderBook.to_name(symbol)
    |> Tai.Markets.OrderBook.update(normalized_changes)

    {:ok, state}
  end

  @doc """
  Log a warning message when the WebSocket receives a message that is not explicitly handled
  """
  def handle_msg(unhandled_msg, state) do
    Logger.warn("unhandled message: #{inspect(unhandled_msg)}")

    {:ok, state}
  end
end
