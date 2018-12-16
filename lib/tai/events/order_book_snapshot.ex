defmodule Tai.Events.OrderBookSnapshot do
  @type order_book :: Tai.Markets.OrderBook.t()
  @type t :: %Tai.Events.OrderBookSnapshot{
          venue_id: atom,
          symbol: atom,
          snapshot: order_book
        }

  @enforce_keys [:venue_id, :symbol, :snapshot]
  defstruct [:venue_id, :symbol, :snapshot]
end

defimpl Tai.LogEvent, for: Tai.Events.OrderBookSnapshot do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    snapshot = event |> Map.get(:snapshot)

    to_price_point = fn {price, {size, sent_at, received_at}}, acc ->
      s = sent_at && sent_at |> DateTime.to_iso8601()
      r = received_at && received_at |> DateTime.to_iso8601()
      price_point = %{price: price, size: size, sent_at: s, received_at: r}
      [price_point | acc]
    end

    bids = snapshot.bids |> Enum.reduce([], to_price_point)
    asks = snapshot.asks |> Enum.reduce([], to_price_point) |> Enum.reverse()

    event
    |> Map.take(keys)
    |> Map.put(:snapshot, %{bids: bids, asks: asks})
  end
end
