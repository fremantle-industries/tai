defmodule Tai.Advisors.HandleInsideQuoteCallbackTest do
  use ExUnit.Case

  defmodule MyAdvisor do
    use Tai.Advisor

    def handle_inside_quote(feed_id, symbol, data, state) do
      if Map.has_key?(state.config, :error) do
        raise state.config.error
      end

      send(:test, {feed_id, symbol, data, state})
      {:ok, state.store}
    end
  end

  defmodule ReturnAdvisor do
    use Tai.Advisor

    def handle_inside_quote(venue_id, product_symbol, data, state) do
      send(:test, {venue_id, product_symbol, data, state})
      state.config[:return_val]
    end
  end

  @btc_usd struct(Tai.Venues.Product, %{venue_id: :my_venue, symbol: :btc_usd})
  defp start_advisor!(advisor, config \\ %{}) do
    start_supervised!({
      advisor,
      [
        group_id: :group_a,
        advisor_id: :my_advisor,
        products: [@btc_usd],
        config: config,
        store: %{},
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
    book_pid = start_supervised!({Tai.Markets.OrderBook, feed_id: :my_venue, symbol: :btc_usd})

    {:ok, %{book_pid: book_pid}}
  end

  test "is called after the snapshot broadcast message" do
    start_advisor!(MyAdvisor)

    snapshot = %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }

    Tai.Markets.OrderBook.replace(snapshot)

    assert_receive {:my_venue, :btc_usd,
                    %{market_quote: received_market_quote, changes: received_snapshot},
                    %Tai.Advisor.State{}}

    assert %Tai.Markets.Quote{} = received_market_quote

    assert %Tai.Markets.PriceLevel{
             price: 101.2,
             size: 1.0,
             processed_at: nil,
             server_changed_at: nil
           } = received_market_quote.bid

    assert %Tai.Markets.PriceLevel{
             price: 101.3,
             size: 0.1,
             processed_at: nil,
             server_changed_at: nil
           } = received_market_quote.ask

    assert received_snapshot == snapshot
  end

  test "is called on broadcast changes when the inside bid price is >= to the previous bid or != size" do
    start_advisor!(MyAdvisor)

    changes_1 = %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }

    Tai.Markets.OrderBook.update(changes_1)

    assert_receive {
      :my_venue,
      :btc_usd,
      %{
        market_quote: %Tai.Markets.Quote{
          bid: %Tai.Markets.PriceLevel{
            price: 101.2,
            size: 1.0,
            processed_at: nil,
            server_changed_at: nil
          },
          ask: %Tai.Markets.PriceLevel{
            price: 101.3,
            size: 0.1,
            processed_at: nil,
            server_changed_at: nil
          }
        },
        changes: ^changes_1
      },
      %Tai.Advisor.State{}
    }

    changes_2 = %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{101.2 => {1.1, nil, nil}},
      asks: %{}
    }

    Tai.Markets.OrderBook.update(changes_2)

    assert_receive {
      :my_venue,
      :btc_usd,
      %{
        market_quote: %Tai.Markets.Quote{
          bid: %Tai.Markets.PriceLevel{
            price: 101.2,
            size: 1.1,
            processed_at: nil,
            server_changed_at: nil
          },
          ask: %Tai.Markets.PriceLevel{
            price: 101.3,
            size: 0.1,
            processed_at: nil,
            server_changed_at: nil
          }
        },
        changes: ^changes_2
      },
      %Tai.Advisor.State{}
    }
  end

  test "is called on broadcast changes when the inside ask price is <= to the previous ask or != size" do
    start_advisor!(MyAdvisor)

    changes_1 = %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }

    Tai.Markets.OrderBook.update(changes_1)

    assert_receive {
      :my_venue,
      :btc_usd,
      %{
        market_quote: %Tai.Markets.Quote{
          bid: %Tai.Markets.PriceLevel{
            price: 101.2,
            size: 1.0,
            processed_at: nil,
            server_changed_at: nil
          },
          ask: %Tai.Markets.PriceLevel{
            price: 101.3,
            size: 0.1,
            processed_at: nil,
            server_changed_at: nil
          }
        },
        changes: ^changes_1
      },
      %Tai.Advisor.State{}
    }

    changes_2 = %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{},
      asks: %{101.3 => {0.2, nil, nil}}
    }

    Tai.Markets.OrderBook.update(changes_2)

    assert_receive {
      :my_venue,
      :btc_usd,
      %{
        market_quote: %Tai.Markets.Quote{
          bid: %Tai.Markets.PriceLevel{
            price: 101.2,
            size: 1.0,
            processed_at: nil,
            server_changed_at: nil
          },
          ask: %Tai.Markets.PriceLevel{
            price: 101.3,
            size: 0.2,
            processed_at: nil,
            server_changed_at: nil
          }
        },
        changes: ^changes_2
      },
      %Tai.Advisor.State{}
    }
  end

  test "can store data in state by returning an {:ok, run_store} tuple" do
    start_advisor!(ReturnAdvisor, %{return_val: {:ok, %{hello: "world"}}})

    snapshot = %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.1, nil, nil}}
    }

    Tai.Markets.OrderBook.replace(snapshot)

    assert_receive {
      :my_venue,
      :btc_usd,
      %{market_quote: %Tai.Markets.Quote{}, changes: ^snapshot},
      %Tai.Advisor.State{advisor_id: :my_advisor, store: %{}}
    }

    changes = %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{},
      asks: %{101.3 => {0.2, nil, nil}}
    }

    Tai.Markets.OrderBook.update(changes)

    assert_receive {
      :my_venue,
      :btc_usd,
      %{market_quote: %Tai.Markets.Quote{}, changes: ^changes},
      %Tai.Advisor.State{advisor_id: :my_advisor, store: %{hello: "world"}}
    }
  end

  describe "with invalid return" do
    setup do
      Tai.Events.firehose_subscribe()
      start_advisor!(ReturnAdvisor, %{return_val: {:unknown, :return_val}})
      :ok
    end

    @snapshot %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.2, nil, nil}}
    }
    @changes %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{},
      asks: %{101.3 => {0.7, nil, nil}}
    }

    test "broadcasts an event" do
      Tai.Markets.OrderBook.replace(@snapshot)

      assert_receive {Tai.Event, %Tai.Events.AdvisorHandleInsideQuoteInvalidReturn{} = event, _}
      assert event.advisor_id == :my_advisor
      assert event.group_id == :group_a
      assert event.venue_id == :my_venue
      assert event.product_symbol == :btc_usd
      assert event.return_value == {:unknown, :return_val}
    end

    test "maintains state between callbacks" do
      Tai.Markets.OrderBook.replace(@snapshot)

      assert_receive {Tai.Event, %Tai.Events.AdvisorHandleInsideQuoteInvalidReturn{} = event_1, _}
      assert event_1.return_value == {:unknown, :return_val}

      Tai.Markets.OrderBook.update(@changes)

      assert_receive {Tai.Event, %Tai.Events.AdvisorHandleInsideQuoteInvalidReturn{} = event_2, _}
      assert event_2.return_value == {:unknown, :return_val}
    end
  end

  describe "with an error" do
    setup do
      Tai.Events.firehose_subscribe()
      start_advisor!(MyAdvisor, %{error: "!!!This is an ERROR!!!"})
      :ok
    end

    @snapshot %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{101.2 => {1.0, nil, nil}},
      asks: %{101.3 => {0.2, nil, nil}}
    }
    @changes %Tai.Markets.OrderBook{
      venue_id: :my_venue,
      product_symbol: :btc_usd,
      bids: %{},
      asks: %{101.3 => {0.7, nil, nil}}
    }

    test "broadcasts an event" do
      Tai.Markets.OrderBook.replace(@snapshot)

      assert_receive {Tai.Event, %Tai.Events.AdvisorHandleInsideQuoteError{} = event, _}
      assert event.advisor_id == :my_advisor
      assert event.group_id == :group_a
      assert event.venue_id == :my_venue
      assert event.product_symbol == :btc_usd
      assert event.error == %RuntimeError{message: "!!!This is an ERROR!!!"}
      assert [stack_1 | _] = event.stacktrace

      assert {Tai.Advisors.HandleInsideQuoteCallbackTest.MyAdvisor, :handle_inside_quote, 4,
              [file: _, line: _]} = stack_1
    end

    test "maintains state between callbacks" do
      Tai.Markets.OrderBook.replace(@snapshot)

      assert_receive {Tai.Event, %Tai.Events.AdvisorHandleInsideQuoteError{} = event_1, _}
      assert event_1.error == %RuntimeError{message: "!!!This is an ERROR!!!"}

      Tai.Markets.OrderBook.update(@changes)

      assert_receive {Tai.Event, %Tai.Events.AdvisorHandleInsideQuoteError{} = event_2, _}
      assert event_2.error == %RuntimeError{message: "!!!This is an ERROR!!!"}
    end
  end
end
