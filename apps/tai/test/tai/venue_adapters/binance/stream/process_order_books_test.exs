defmodule Tai.VenueAdapters.Binance.Stream.ProcessOrderBooksTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Binance.Stream.{OrderBookStore, ProcessOrderBooks}

  @venue :venue_a
  @venue_symbol "BTC_USD"
  @product struct(Tai.Venues.Product, venue_id: @venue, venue_symbol: @venue_symbol)
  @received_at Timex.now()

  setup do
    name = OrderBookStore.to_name(@venue, @venue_symbol)
    Process.register(self(), name)
    {:ok, pid} = start_supervised({ProcessOrderBooks, [venue_id: @venue, products: [@product]]})

    {:ok, %{pid: pid}}
  end

  test "forwards an update message to the order book store for the product", %{pid: pid} do
    venue_msg = %{
      "data" => %{
        "e" => "depthUpdate",
        "E" => 1_569_051_459_755,
        "s" => @venue_symbol,
        "U" => "ignore",
        "u" => "ignore",
        "b" => [],
        "a" => []
      },
      "stream" => "ignore"
    }

    GenServer.cast(pid, {venue_msg, @received_at})

    assert_receive {:"$gen_cast", {:update, data, received_at}}
    assert %{"E" => 1_569_051_459_755} = data
    assert received_at == @received_at
  end
end
