defmodule Tai.VenueAdapters.Binance.Stream.TradesTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Binance.Stream.ProcessOptionalChannels
  alias Tai.{Events, Venues}

  setup do
    product =
      struct(Venues.Product, %{
        venue_id: :my_venue,
        symbol: :bnb_btc,
        venue_symbol: "BNBBTC"
      })

    start_supervised!({Tai.Events, 1})
    start_supervised!({ProcessOptionalChannels, [venue_id: product.venue_id]})
    start_supervised!(Venues.ProductStore)
    Venues.ProductStore.upsert(product)

    %{product: product}
  end

  test "broadcasts an event when public trade is received", %{product: product} do
    Events.firehose_subscribe()
    venue_trade_id = 42

    trade = %{
      "e" => "trade",
      "E" => venue_trade_id,
      "s" => product.venue_symbol,
      "t" => 12345,
      "p" => "0.001",
      "q" => "100",
      "b" => 88,
      "a" => 50,
      "T" => 123_456_785,
      "m" => true,
      "M" => true
    }

    product.venue_id
    |> ProcessOptionalChannels.to_name()
    |> GenServer.cast({%{"data" => trade}, :ignore})

    assert_event(%Events.Trade{venue_trade_id: venue_trade_id})
  end
end
