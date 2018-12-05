defmodule Tai.VenueAdapters.Mock.OrderBookFeed do
  @moduledoc """
  Mock adapter for an order book feed. Simulate a stream of order book updates
  """

  use Tai.Venues.OrderBookFeed
  alias Tai.VenueAdapters.Mock.OrderBookFeed

  def default_url, do: "ws://localhost:#{EchoBoy.Config.port()}/ws"

  def subscribe_to_order_books(_pid, :subscribe_error, symbols) do
    {:error, "could not subscribe to #{symbols.join(",")}"}
  end

  def subscribe_to_order_books(_pid, _feed_id, _symbols), do: :ok

  def handle_msg(
        %{
          "type" => "snapshot",
          "symbol" => raw_symbol,
          "bids" => bids,
          "asks" => asks
        },
        state
      ) do
    symbol = String.to_atom(raw_symbol)
    processed_at = Timex.now()

    snapshot = %Tai.Markets.OrderBook{
      bids: OrderBookFeed.Snapshot.normalize(bids, processed_at),
      asks: OrderBookFeed.Snapshot.normalize(asks, processed_at)
    }

    [feed_id: state.feed_id, symbol: symbol]
    |> Tai.Markets.OrderBook.to_name()
    |> Tai.Markets.OrderBook.replace(snapshot)

    {:ok, state}
  end
end
