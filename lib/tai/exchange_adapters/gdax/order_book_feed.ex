defmodule Tai.ExchangeAdapters.Gdax.OrderBookFeed do
  @moduledoc """
  WebSocket order book feed adapter for GDAX
  """

  use Tai.Exchanges.OrderBookFeed

  require Logger

  alias Tai.{Exchanges.OrderBookFeed, Markets.OrderBook}
  alias Tai.ExchangeAdapters.Gdax.{Product, Serializers.Snapshot, Serializers.L2Update}

  @doc """
  Secure production GDAX WebSocket url
  """
  def default_url, do: "wss://ws-feed.gdax.com/"

  @doc """
  Subscribe to the level2 channel for the configured symbols
  """
  def subscribe_to_order_books(name, symbols) do
    [name: name, symbols: symbols, channels: ["level2"]]
    |> subscribe
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
    [feed_id: feed_id, symbol: Product.to_symbol(product_id)]
    |> OrderBook.to_name
    |> OrderBook.replace(
      bids: bids |> Snapshot.normalize,
      asks: asks |> Snapshot.normalize
    )
  end
  @doc """
  Update the bids/asks in the order books that have changed
  """
  def handle_msg(
    %{
      "type" => "l2update",
      "time" => _time,
      "product_id" => product_id,
      "changes" => changes
    },
    feed_id
  ) do
    normalized_changes = changes |> L2Update.normalize
    symbol = product_id |> Product.to_symbol

    [feed_id: feed_id, symbol: symbol]
    |> OrderBook.to_name
    |> OrderBook.update(normalized_changes)
  end
  @doc """
  Log a warning message when the WebSocket receives a message that is not explicitly handled
  """
  def handle_msg(unhandled_msg, feed_id) do
    Logger.warn "[#{feed_id |> OrderBookFeed.to_name}] unhandled message: #{inspect unhandled_msg}"
  end

  defp subscribe(name: name, symbols: symbols, channels: channels) do
    [
      name: name,
      msg: %{
        "type" => "subscribe",
        "product_ids" => Product.to_product_ids(symbols),
        "channels" => channels
      }
    ]
    |> send_msg
  end

  defp send_msg(name: name, msg: msg) do
    name
    |> WebSockex.send_frame({:text, JSON.encode!(msg)})
  end
end
