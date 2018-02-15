defmodule Tai.ExchangeAdapters.Gdax.OrderBookFeed do
  use Tai.Exchanges.OrderBookFeed

  require Logger

  alias Tai.Markets.OrderBook
  alias Tai.ExchangeAdapters.Gdax.Product

  def url, do: "wss://ws-feed.gdax.com/"

  def subscribe_to_order_books(name, symbols) do
    [name: name, symbols: symbols, channels: ["level2"]]
    |> subscribe
  end

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
    |> OrderBook.replace(bids: bids |> normalize_snapshot, asks: asks |> normalize_snapshot)
  end
  def handle_msg(
    %{
      "type" => "l2update",
      "time" => _time,
      "product_id" => product_id,
      "changes" => changes
    },
    feed_id
  ) do
    [feed_id: feed_id, symbol: Product.to_symbol(product_id)]
    |> OrderBook.to_name
    |> OrderBook.update(changes |> normalize_changes)
  end
  def handle_msg(unhandled_msg, feed_id) do
    Logger.warn "#{feed_id |> Tai.Exchanges.OrderBookFeed.to_name} unhandled message: #{inspect unhandled_msg}"
  end

  defp normalize_snapshot(side_snapshot) do
    []
    |> normalize_snapshot(side_snapshot)
  end
  defp normalize_snapshot(acc, []), do: acc
  defp normalize_snapshot(acc, [[price, size] | remaining]) do
    {parsed_price, _} = Float.parse(price)
    {parsed_size, _} = Float.parse(size)

    [{parsed_price, parsed_size} | acc]
    |> normalize_snapshot(remaining)
  end

  defp normalize_side("buy"), do: :bid
  defp normalize_side("sell"), do: :ask

  defp normalize_changes(changes) do
    []
    |> normalize_changes(changes)
  end
  defp normalize_changes(acc, []), do: acc
  defp normalize_changes(acc, [[side, price, size] | remaining_changes]) do
    {parsed_price, _} = Float.parse(price)
    {parsed_size, _} = Float.parse(size)

    [[side: side |> normalize_side, price: parsed_price, size: parsed_size] | acc]
    |> normalize_changes(remaining_changes)
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

  # defp unsubscribe_from_order_book(name, symbols) do
  #   [name: name, symbols: symbols, channels: ["level2"]]
  #   |> unsubscribe
  # end

  # defp unsubscribe(name: name, symbols: symbols, channels: channels) do
  #   [
  #     name: name,
  #     msg: %{
  #       "type" => "unsubscribe",
  #       "product_ids" => Product.to_product_ids(symbols),
  #       "channels" => channels
  #     }
  #   ]
  #   |> send_msg
  # end

  defp send_msg(name: name, msg: msg) do
    name
    |> WebSockex.send_frame({:text, JSON.encode!(msg)})
  end
end
