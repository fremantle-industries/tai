defmodule Support.ForwardOrderBookEvents do
  use GenServer

  def start_link([feed_id: _, symbol: _] = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init([feed_id: feed_id, symbol: symbol] = state) do
    Tai.PubSub.subscribe([
      {:order_book_snapshot, feed_id, symbol},
      {:order_book_changes, feed_id, symbol}
    ])

    {:ok, state}
  end

  def handle_info({:order_book_snapshot, _feed_id, _symbol, _snapshot} = msg, state) do
    send(:test, msg)
    {:noreply, state}
  end

  def handle_info({:order_book_changes, _feed_id, _symbol, _snapshot} = msg, state) do
    send(:test, msg)
    {:noreply, state}
  end
end
