defmodule Examples.Advisors.LogSpread.AdvisorTest do
  use ExUnit.Case, async: false

  import Tai.TestSupport.Mock
  alias Tai.TestSupport.Mocks

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    start_supervised!(Tai.TestSupport.Mocks.Server)
    mock_product_responses()
    {:ok, _} = Application.ensure_all_started(:tai)

    start_supervised!({
      Examples.Advisors.LogSpread.Advisor,
      [
        group_id: :log_spread,
        advisor_id: :btc_usd,
        products: [
          struct(
            Tai.Venues.Product,
            %{venue_id: :test_exchange_a, symbol: :btc_usd}
          )
        ],
        config: %{},
        store: %{},
        trades: []
      ]
    })

    :ok
  end

  test "logs the bid/ask spread with a custom event" do
    Tai.Events.firehose_subscribe()

    push_market_data_snapshot(
      %Tai.Markets.Location{
        venue_id: :test_exchange_a,
        product_symbol: :btc_usd
      },
      %{6500.1 => 1.1},
      %{6500.11 => 1.2}
    )

    assert_receive {Tai.Event,
                    %Examples.Advisors.LogSpread.Events.Spread{
                      venue_id: :test_exchange_a,
                      product_symbol: :btc_usd,
                      bid_price: "6500.1",
                      ask_price: "6500.11",
                      spread: "0.01"
                    }, _}
  end

  def mock_product_responses do
    Mocks.Responses.Products.for_venue(
      :test_exchange_a,
      [
        %{symbol: :btc_usd},
        %{symbol: :ltc_usd}
      ]
    )

    Mocks.Responses.Products.for_venue(
      :test_exchange_b,
      [
        %{symbol: :eth_usd},
        %{symbol: :ltc_usd}
      ]
    )
  end
end
