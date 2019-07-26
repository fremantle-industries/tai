defmodule Tai.Events.OrderBookSnapshotTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms price points to a json serializable format" do
    date_str = "2016-02-29T22:25:00-06:00"
    {:ok, date} = Timex.parse(date_str, "{ISO:Extended}")

    order_book = %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{
        999.9 => {1.1, date, date},
        999.8 => {1.2, date, date}
      },
      asks: %{
        1000.0 => {0.1, date, date},
        1000.1 => {0.2, date, date}
      }
    }

    event = %Tai.Events.OrderBookSnapshot{
      venue_id: :my_venue,
      symbol: :btc_usd,
      snapshot: order_book
    }

    assert %{
             venue_id: :my_venue,
             symbol: :btc_usd,
             snapshot: %{bids: bids, asks: asks}
           } = Tai.LogEvent.to_data(event)

    assert [
             %{price: 999.9, size: 1.1, sent_at: ^date_str, received_at: ^date_str},
             %{price: 999.8, size: 1.2, sent_at: ^date_str, received_at: ^date_str}
           ] = bids

    assert [
             %{price: 1000.0, size: 0.1, sent_at: ^date_str, received_at: ^date_str},
             %{price: 1000.1, size: 0.2, sent_at: ^date_str, received_at: ^date_str}
           ] = asks
  end
end
