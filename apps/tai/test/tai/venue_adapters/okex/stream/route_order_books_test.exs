defmodule Tai.VenueAdapters.OkEx.Stream.RouteOrderBooksTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.OkEx.Stream.{ProcessOrderBook, RouteOrderBooks}

  @venue :venue_a
  @venue_symbol "BTC-USD-SWAP"
  @product struct(Tai.Venues.Product, venue_id: @venue, venue_symbol: @venue_symbol)
  @received_at Timex.now()

  setup do
    name = ProcessOrderBook.to_name(@venue, @venue_symbol)
    Process.register(self(), name)
    {:ok, pid} = start_supervised({RouteOrderBooks, [venue: @venue, products: [@product]]})

    {:ok, %{pid: pid}}
  end

  test "forwards a partial message to the order book store for the product", %{pid: pid} do
    venue_msg = %{"action" => "partial", "data" => [%{"instrument_id" => @venue_symbol}]}

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:snapshot, data, received_at}}
    assert data == %{"instrument_id" => "BTC-USD-SWAP"}
    assert received_at == @received_at
  end

  test "forwards an update message to the order book store for the product", %{pid: pid} do
    venue_msg = %{"action" => "update", "data" => [%{"instrument_id" => @venue_symbol}]}

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:update, data, received_at}}
    assert data == %{"instrument_id" => "BTC-USD-SWAP"}
    assert received_at == @received_at
  end
end
