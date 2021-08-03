defmodule Tai.VenueAdapters.Binance.Stream.RouteOrderBooksTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Binance.Stream.{ProcessOrderBook, RouteOrderBooks}

  @venue :venue_a
  @venue_symbol "BTC_USD"
  @product struct(Tai.Venues.Product, venue_id: @venue, venue_symbol: @venue_symbol)
  @received_at Timex.now()

  setup do
    name = ProcessOrderBook.to_name(@venue, @venue_symbol)
    Process.register(self(), name)
    {:ok, pid} = start_supervised({RouteOrderBooks, [venue_id: @venue, order_books: [@product]]})

    {:ok, %{pid: pid}}
  end

  test "forwards an update message to the order book store for the product", %{pid: pid} do
    msg = %{
      "e" => "depthUpdate",
      "E" => 1_569_051_459_755,
      "s" => @venue_symbol,
      "U" => "ignore",
      "u" => "ignore",
      "b" => [],
      "a" => []
    }

    GenServer.cast(pid, {msg, @received_at})

    assert_receive {:"$gen_cast", {:update, received_msg, received_at}}
    assert received_msg == msg
    assert received_at == @received_at
  end
end
