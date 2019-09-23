defmodule Tai.VenueAdapters.Bitmex.Stream.RouteOrderBooksTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.{ProcessOrderBook, RouteOrderBooks}

  @venue :venue_a
  @venue_symbol "XBTUSD"
  @product struct(Tai.Venues.Product, venue_symbol: @venue_symbol)
  @received_at Timex.now()

  setup do
    name = ProcessOrderBook.to_name(@venue, @venue_symbol)
    Process.register(self(), name)
    {:ok, pid} = start_supervised({RouteOrderBooks, [venue_id: @venue, products: [@product]]})

    {:ok, %{pid: pid}}
  end

  test "forwards a partial message to the order book store for the product", %{pid: pid} do
    venue_msg = %{"action" => "partial", "filter" => %{"symbol" => @venue_symbol}, "data" => []}

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:snapshot, data, received_at}}
    assert data == []
    assert received_at == @received_at
  end

  test "forwards an insert message to the order book store for the product", %{pid: pid} do
    venue_msg = %{"action" => "insert", "data" => [%{"symbol" => @venue_symbol}]}

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:insert, data, received_at}}
    assert data == [%{"symbol" => @venue_symbol}]
    assert received_at == @received_at
  end

  test "forwards an update message to the order book store for the product", %{pid: pid} do
    venue_msg = %{"action" => "update", "data" => [%{"symbol" => @venue_symbol}]}

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:update, data, received_at}}
    assert data == [%{"symbol" => @venue_symbol}]
    assert received_at == @received_at
  end

  test "forwards a delete message to the order book store for the product", %{pid: pid} do
    venue_msg = %{"action" => "delete", "data" => [%{"symbol" => @venue_symbol}]}

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:delete, data, received_at}}
    assert data == [%{"symbol" => @venue_symbol}]
    assert received_at == @received_at
  end
end
