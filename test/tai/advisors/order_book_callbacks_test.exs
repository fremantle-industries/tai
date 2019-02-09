defmodule Tai.Advisors.OrderBookCallbacksTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  defmodule MyAdvisor do
    use Tai.Advisor

    def handle_order_book_changes(feed_id, symbol, changes, state) do
      send(:test, {feed_id, symbol, changes, state})
    end

    def handle_inside_quote(feed_id, symbol, inside_quote, changes, state) do
      if Map.has_key?(state.config, :error) do
        raise state.config.error
      end

      send(:test, {feed_id, symbol, inside_quote, changes, state})
      state.config[:return_val] || {:ok, state.store}
    end
  end

  @btc_usd struct(Tai.Venues.Product, %{exchange_id: :my_venue, symbol: :btc_usd})
  defp start_advisor!(advisor, config \\ %{}) do
    start_supervised!({
      advisor,
      [
        group_id: :group_a,
        advisor_id: :my_advisor,
        products: [@btc_usd],
        config: config
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

    start_supervised!(
      {Tai.ExchangeAdapters.Mock.Account,
       [exchange_id: :my_test_exchange, account_id: :my_test_account, credentials: %{}]}
    )

    {:ok, %{book_pid: book_pid}}
  end

  describe "#handle_order_book_changes" do
    test "is called when it receives a broadcast message" do
      start_advisor!(MyAdvisor)

      changes = %Tai.Markets.OrderBook{
        venue_id: :my_venue,
        product_symbol: :btc_usd,
        bids: %{101.2 => {1.1, nil, nil}},
        asks: %{}
      }

      Tai.Markets.OrderBook.update(changes)

      assert_receive {:my_venue, :btc_usd, ^changes, %Tai.Advisor{}}
    end
  end

  describe "#handle_inside_quote" do
    test "is called after the snapshot broadcast message" do
      start_advisor!(MyAdvisor)

      snapshot = %Tai.Markets.OrderBook{
        venue_id: :my_venue,
        product_symbol: :btc_usd,
        bids: %{101.2 => {1.0, nil, nil}},
        asks: %{101.3 => {0.1, nil, nil}}
      }

      Tai.Markets.OrderBook.replace(snapshot)

      assert_receive {:my_venue, :btc_usd, received_market_quote, received_snapshot,
                      %Tai.Advisor{}}

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
        %Tai.Markets.Quote{
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
        ^changes_1,
        %Tai.Advisor{}
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
        %Tai.Markets.Quote{
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
        ^changes_2,
        %Tai.Advisor{}
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
        %Tai.Markets.Quote{
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
        ^changes_1,
        %Tai.Advisor{}
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
        %Tai.Markets.Quote{
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
        ^changes_2,
        %Tai.Advisor{}
      }
    end

    test "logs a warning message when it returns an unknown type" do
      start_advisor!(MyAdvisor, %{return_val: {:unknown, :return_val}})

      log_msg =
        capture_log(fn ->
          snapshot = %Tai.Markets.OrderBook{
            venue_id: :my_venue,
            product_symbol: :btc_usd,
            bids: %{101.2 => {1.0, nil, nil}},
            asks: %{}
          }

          Tai.Markets.OrderBook.replace(snapshot)
          :timer.sleep(100)
        end)

      assert log_msg =~
               "[warn]  handle_inside_quote returned an invalid value: '{:unknown, :return_val}'"
    end

    test "can store data in state by returning an {:ok, run_store} tuple" do
      start_advisor!(MyAdvisor, %{return_val: {:ok, %{hello: "world"}}})

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
        %Tai.Markets.Quote{},
        ^snapshot,
        %Tai.Advisor{advisor_id: :my_advisor, store: %{}}
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
        %Tai.Markets.Quote{},
        ^changes,
        %Tai.Advisor{advisor_id: :my_advisor, store: %{hello: "world"}}
      }
    end

    test "logs a warning message when an error is raised" do
      start_advisor!(MyAdvisor, %{error: "!!!This is an ERROR!!!"})

      log_msg =
        capture_log(fn ->
          snapshot = %Tai.Markets.OrderBook{
            venue_id: :my_venue,
            product_symbol: :btc_usd,
            bids: %{101.2 => {1.0, nil, nil}},
            asks: %{}
          }

          Tai.Markets.OrderBook.replace(snapshot)
          :timer.sleep(100)
        end)

      assert log_msg =~
               "[warn]  handle_inside_quote raised an error: '%RuntimeError{message: \"!!!This is an ERROR!!!\"}', " <>
                 "stacktrace: [{Tai.Advisors.OrderBookCallbacksTest.MyAdvisor, :handle_inside_quote, 5, [file: 'test/tai/advisors/order_book_callbacks_test.exs', line:"
    end
  end
end
