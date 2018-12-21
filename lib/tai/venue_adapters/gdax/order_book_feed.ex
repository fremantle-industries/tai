defmodule Tai.VenueAdapters.Gdax.OrderBookFeed do
  @moduledoc """
  WebSocket order book feed adapter for GDAX
  """

  use Tai.Venues.OrderBookFeed
  alias Tai.VenueAdapters.Gdax.OrderBookFeed
  alias Tai.ExchangeAdapters.Gdax.{Product}
  require Logger

  @doc """
  Secure production GDAX WebSocket url
  """
  def default_url, do: "wss://ws-feed.gdax.com/"

  @doc """
  Subscribe to the level2 channel for the configured symbols
  """
  def subscribe_to_order_books(pid, _feed_id, symbols) do
    gdax_product_ids = Product.to_product_ids(symbols)

    msg = %{
      "type" => "subscribe",
      "product_ids" => gdax_product_ids,
      "channels" => ["level2"]
    }

    pid
    |> Tai.WebSocket.send_json_msg(msg)
    |> case do
      :ok ->
        :ok

      {:error, _} = error ->
        error
    end
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
        state
      ) do
    processed_at = Timex.now()

    symbol = Product.to_symbol(product_id)

    snapshot = %Tai.Markets.OrderBook{
      venue_id: state.feed_id,
      product_symbol: symbol,
      bids: bids |> OrderBookFeed.Snapshot.normalize(processed_at),
      asks: asks |> OrderBookFeed.Snapshot.normalize(processed_at)
    }

    Tai.Markets.OrderBook.replace(snapshot)

    {:ok, state}
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
        state
      ) do
    processed_at = Timex.now()
    server_changed_at = Timex.parse!(time, "{ISO:Extended}")

    symbol = product_id |> Product.to_symbol()

    normalized_changes =
      OrderBookFeed.L2Update.normalize(
        state.feed_id,
        symbol,
        changes,
        processed_at,
        server_changed_at
      )

    Tai.Markets.OrderBook.update(normalized_changes)

    {:ok, state}
  end

  @doc """
  Log an info message with the products that were successfully subscribed to
  """
  def handle_msg(
        %{
          "channels" => [
            %{
              "name" => "level2",
              "product_ids" => product_ids
            }
          ],
          "type" => "subscriptions"
        },
        state
      ) do
    Logger.info("successfully subscribed to #{inspect(product_ids)}")

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
