defmodule Tai.VenueAdapters.Gdax.Stream.RouteOrderBooksTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Gdax.Stream.{ProcessOrderBook, RouteOrderBooks}

  @venue :venue_a
  @venue_symbol "BTC-USD"
  @product struct(Tai.Venues.Product, venue_symbol: @venue_symbol)
  @received_at Timex.now()

  setup do
    name = ProcessOrderBook.to_name(@venue, @venue_symbol)
    Process.register(self(), name)
    {:ok, pid} = start_supervised({RouteOrderBooks, [venue_id: @venue, order_books: [@product]]})

    {:ok, %{pid: pid}}
  end

  test "forwards a snapshot message to the order book store for the product", %{pid: pid} do
    venue_msg = %{"type" => "snapshot", "product_id" => @venue_symbol}

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:snapshot, data, received_at}}
    assert data == venue_msg
    assert received_at == @received_at
  end

  test "forwards an update message to the order book store for the product", %{pid: pid} do
    venue_msg = %{"type" => "l2update", "product_id" => @venue_symbol}

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:update, data, received_at}}
    assert data == venue_msg
    assert received_at == @received_at
  end
end
