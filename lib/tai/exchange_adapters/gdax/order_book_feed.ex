defmodule Tai.ExchangeAdapters.Gdax.OrderBookFeed do
  @moduledoc """
  WebSocket order book feed adapter for GDAX
  """

  use Tai.Exchanges.OrderBookFeed

  require Logger

  alias Tai.{Exchanges.OrderBookFeed, Markets.OrderBook, PubSub}
  alias Tai.ExchangeAdapters.Gdax.{Product, Serializers.Snapshot, Serializers.L2Update}

  @doc """
  Secure production GDAX WebSocket url
  """
  def default_url, do: "wss://ws-feed.gdax.com/"

  @doc """
  Subscribe to the level2 channel for the configured symbols
  """
  def subscribe_to_order_books(pid, _feed_id, symbols) do
    send_msg(
      pid,
      %{
        "type" => "subscribe",
        "product_ids" => Product.to_product_ids(symbols),
        "channels" => ["level2"]
      }
    )
  end

  @doc """
  Replace the bids/asks in the order books with the initial GDAX snapshot
  """
  def handle_msg(
    %{
      "type" => "snapshot",
      "product_id" => product_id,
      "bids" => bids,
      "asks" => asks
    },
    feed_id
  ) do
    processed_at = Timex.now
    normalized_bids = bids |> Snapshot.normalize(processed_at)
    normalized_asks = asks |> Snapshot.normalize(processed_at)
    symbol = Product.to_symbol(product_id)

    [feed_id: feed_id, symbol: symbol]
    |> OrderBook.to_name
    |> OrderBook.replace(%{
      bids: normalized_bids,
      asks: normalized_asks
    })
    |> broadcast_order_book_snapshot(feed_id, symbol, normalized_bids, normalized_asks)
  end
  @doc """
  Update the bids/asks in the order books that have changed
  """
  def handle_msg(
    %{
      "type" => "l2update",
      "time" => time,
      "product_id" => product_id,
      "changes" => changes
    },
    feed_id
  ) do
    processed_at = Timex.now
    server_changed_at = Timex.parse!(time, "{ISO:Extended}")
    normalized_changes = changes |> L2Update.normalize(processed_at, server_changed_at)
    symbol = product_id |> Product.to_symbol

    [feed_id: feed_id, symbol: symbol]
    |> OrderBook.to_name
    |> OrderBook.update(normalized_changes)
    |> broadcast_order_book_changes(feed_id, symbol, normalized_changes)
  end
  @doc """
  Log a warning message when the WebSocket receives a message that is not explicitly handled
  """
  def handle_msg(unhandled_msg, feed_id) do
    Logger.warn "[#{feed_id |> OrderBookFeed.to_name}] unhandled message: #{inspect unhandled_msg}"
  end

  defp send_msg(pid, msg) do
    WebSockex.send_frame(pid, {:text, JSON.encode!(msg)})
  end
end
