defmodule Tai.NewAdvisors.HandleMarketQuoteTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Markets.{Quote, PricePoint}

  defmodule MyAdvisor do
    use Tai.NewAdvisor

    def handle_market_quote(market_quote, state) do
      if Map.has_key?(state.config, :error) do
        raise state.config.error
      end

      counter = state.store |> Map.get(:event_counter, 0)
      new_store = state.store |> Map.put(:event_counter, counter + 1)
      send(:test, {:handle_event_called, market_quote})

      if Map.has_key?(state.config, :return_val) do
        state.config[:return_val]
      else
        {:ok, new_store}
      end
    end
  end

  @venue :my_venue
  @symbol :btc_usd
  @fleet_id :fleet_a
  @advisor_id :my_advisor
  @advisor_process Tai.NewAdvisor.process_name(@fleet_id, @advisor_id)
  @market_quote %Quote{
    venue_id: @venue,
    product_symbol: @symbol,
    bids: [%PricePoint{price: 101.2, size: 1.0}],
    asks: [%PricePoint{price: 101.3, size: 0.1}],
    last_received_at: System.monotonic_time()
  }

  defp start_advisor!(advisor, config \\ %{}) do
    start_supervised!({
      advisor,
      [
        advisor_id: @advisor_id,
        fleet_id: @fleet_id,
        quote_keys: [{@venue, @symbol}],
        config: config,
        store: %{event_counter: 0}
      ]
    })
  end

  setup do
    Process.register(self(), :test)
    mock_product(%{venue_id: @venue, symbol: @symbol})

    :ok
  end

  test "fires the handle_event callback for market quotes" do
    start_advisor!(MyAdvisor)

    send(@advisor_process, {:market_quote_store, :after_put, @market_quote})

    assert_receive {:handle_event_called, received_market_quote}

    assert received_market_quote.venue_id == @venue
    assert received_market_quote.product_symbol == @symbol

    assert %PricePoint{} = inside_bid = received_market_quote.bids |> hd()
    assert inside_bid.price == 101.2
    assert inside_bid.size == 1.0

    assert %PricePoint{} = inside_ask = received_market_quote.asks |> hd()
    assert inside_ask.price == 101.3
    assert inside_ask.size == 0.1
  end

  test "emits an event and maintains state between callbacks when return is invalid" do
    TaiEvents.firehose_subscribe()
    start_advisor!(MyAdvisor, %{return_val: {:unknown, :return_val}})

    send(@advisor_process, {:market_quote_store, :after_put, @market_quote})

    assert_receive {
      TaiEvents.Event,
      %Tai.Events.NewAdvisorHandleMarketQuoteInvalidReturn{} = event,
      :warn
    }

    assert event.advisor_id == :my_advisor
    assert event.fleet_id == :fleet_a
    assert event.event == @market_quote
    assert event.return_value == {:unknown, :return_val}

    send(@advisor_process, {:market_quote_store, :after_put, @market_quote})

    assert_receive {TaiEvents.Event, %Tai.Events.NewAdvisorHandleMarketQuoteInvalidReturn{} = event_2, _}
    assert event_2.return_value == {:unknown, :return_val}
  end

  test "emits an event and maintains state between callbacks when an error is raised" do
    TaiEvents.firehose_subscribe()
    start_advisor!(MyAdvisor, %{error: "!!!This is an ERROR!!!"})

    send(@advisor_process, {:market_quote_store, :after_put, @market_quote})

    assert_receive {
      TaiEvents.Event,
      %Tai.Events.NewAdvisorHandleMarketQuoteError{} = event_1,
      :warn
    }

    assert event_1.advisor_id == :my_advisor
    assert event_1.fleet_id == :fleet_a
    assert event_1.event == @market_quote
    assert event_1.error == %RuntimeError{message: "!!!This is an ERROR!!!"}
    assert [stack_1 | _] = event_1.stacktrace

    assert {
             Tai.NewAdvisors.HandleMarketQuoteTest.MyAdvisor,
             :handle_market_quote,
             2,
             [file: _, line: _]
           } = stack_1

    send(@advisor_process, {:market_quote_store, :after_put, @market_quote})

    assert_receive {
      TaiEvents.Event,
      %Tai.Events.NewAdvisorHandleMarketQuoteError{} = event_2,
      :warn
    }

    assert event_2.error == %RuntimeError{message: "!!!This is an ERROR!!!"}
  end
end
