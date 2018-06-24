defmodule Tai.ExchangeAdapters.Mock.OrderBookFeed do
  @moduledoc """
  Mock adapter for an order book feed. Simulate a stream of order book updates
  """

  use Tai.Exchanges.OrderBookFeed

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
        %Tai.Exchanges.OrderBookFeed{feed_id: feed_id} = state
      ) do
    with symbol <- String.to_atom(raw_symbol),
         processed_at <- Timex.now() do
      snapshot = %Tai.Markets.OrderBook{
        bids: Tai.ExchangeAdapters.Mock.Snapshot.normalize(bids, processed_at),
        asks: Tai.ExchangeAdapters.Mock.Snapshot.normalize(asks, processed_at)
      }

      [feed_id: feed_id, symbol: symbol]
      |> Tai.Markets.OrderBook.to_name()
      |> Tai.Markets.OrderBook.replace(snapshot)
    end

    {:ok, state}
  end
end
