defmodule Tai.Advisors.HandleEventTest do
  use ExUnit.Case, async: false
  alias Tai.Markets.{Quote, PricePoint}

  defmodule MyAdvisor do
    use Tai.Advisor

    def handle_event(market_quote, state) do
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
  @group_id :group_a
  @advisor_id :my_advisor
  @advisor_name Tai.Advisor.to_name(@group_id, @advisor_id)
  @product struct(Tai.Venues.Product, %{venue_id: @venue, symbol: @symbol})
  @market_quote %Quote{
    venue_id: @venue,
    product_symbol: @symbol,
    bids: [%PricePoint{price: 101.2, size: 1.0}],
    asks: [%PricePoint{price: 101.3, size: 0.1}]
  }

  defp start_advisor!(advisor, config \\ %{}) do
    start_supervised!({
      advisor,
      [
        group_id: @group_id,
        advisor_id: @advisor_id,
        products: [@product],
        config: config,
        store: %{event_counter: 0},
        trades: []
      ]
    })
  end

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai)
    end)

    Process.register(self(), :test)
    {:ok, _} = Application.ensure_all_started(:tai)

    :ok
  end

  test "fires the handle_event callback for market quotes" do
    start_advisor!(MyAdvisor)

    send(@advisor_name, {:tai, @market_quote})

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
    Tai.Events.firehose_subscribe()
    start_advisor!(MyAdvisor, %{return_val: {:unknown, :return_val}})

    send(@advisor_name, {:tai, @market_quote})

    assert_receive {
      Tai.Event,
      %Tai.Events.AdvisorHandleEventInvalidReturn{} = event,
      :warn
    }

    assert event.advisor_id == :my_advisor
    assert event.group_id == :group_a
    assert event.event == @market_quote
    assert event.return_value == {:unknown, :return_val}

    send(@advisor_name, {:tai, @market_quote})

    assert_receive {Tai.Event, %Tai.Events.AdvisorHandleEventInvalidReturn{} = event_2, _}
    assert event_2.return_value == {:unknown, :return_val}
  end

  test "emits an event and maintains state between callbacks when an error is raised" do
    Tai.Events.firehose_subscribe()
    start_advisor!(MyAdvisor, %{error: "!!!This is an ERROR!!!"})

    send(@advisor_name, {:tai, @market_quote})

    assert_receive {
      Tai.Event,
      %Tai.Events.AdvisorHandleEventError{} = event_1,
      :warn
    }

    assert event_1.advisor_id == :my_advisor
    assert event_1.group_id == :group_a
    assert event_1.event == @market_quote
    assert event_1.error == %RuntimeError{message: "!!!This is an ERROR!!!"}
    assert [stack_1 | _] = event_1.stacktrace

    assert {
             Tai.Advisors.HandleEventTest.MyAdvisor,
             :handle_event,
             2,
             [file: _, line: _]
           } = stack_1

    send(@advisor_name, {:tai, @market_quote})

    assert_receive {
      Tai.Event,
      %Tai.Events.AdvisorHandleEventError{} = event_2,
      :warn
    }

    assert event_2.error == %RuntimeError{message: "!!!This is an ERROR!!!"}
  end
end
