defmodule Tai.Advisors.OrderBookCallbacksTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  defmodule MyAdvisor do
    use Tai.Advisor

    def handle_order_book_changes(feed_id, symbol, changes, state) do
      send(:test, {feed_id, symbol, changes, state})
    end

    def handle_inside_quote(feed_id, symbol, inside_quote, changes, state) do
      if Map.has_key?(state.store, :error) do
        raise state.store.error
      end

      send(:test, {feed_id, symbol, inside_quote, changes, state})
      state.store[:return_val] || :ok
    end
  end

  defp start_advisor!(advisor, store \\ %{}) do
    start_supervised!({
      advisor,
      [
        advisor_id: :my_advisor,
        order_books: %{my_order_book_feed: [:btc_usd]},
        store: store
      ]
    })
  end

  setup do
    on_exit(fn ->
      Tai.Trading.OrderStore.clear()
    end)

    Process.register(self(), :test)

    book_pid =
      start_supervised!({Tai.Markets.OrderBook, feed_id: :my_order_book_feed, symbol: :btc_usd})

    start_supervised!(
      {Tai.ExchangeAdapters.Mock.Account,
       [exchange_id: :my_test_exchange, account_id: :my_test_account, credentials: %{}]}
    )

    {:ok, %{book_pid: book_pid}}
  end

  describe "#handle_order_book_changes" do
    test("is called when it receives a broadcast message", %{
      book_pid: book_pid
    }) do
      start_advisor!(MyAdvisor)

      changes = %Tai.Markets.OrderBook{bids: %{101.2 => {1.1, nil, nil}}, asks: %{}}
      Tai.Markets.OrderBook.update(book_pid, changes)

      assert_receive {
        :my_order_book_feed,
        :btc_usd,
        ^changes,
        %Tai.Advisor{}
      }
    end
  end

  describe "#handle_inside_quote" do
    test("is called after the snapshot broadcast message", %{book_pid: book_pid}) do
      start_advisor!(MyAdvisor)

      snapshot = %Tai.Markets.OrderBook{
        bids: %{101.2 => {1.0, nil, nil}},
        asks: %{101.3 => {0.1, nil, nil}}
      }

      Tai.Markets.OrderBook.replace(book_pid, snapshot)

      assert_receive {
        :my_order_book_feed,
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
        ^snapshot,
        %Tai.Advisor{}
      }
    end

    test(
      "is called on broadcast changes when the inside bid price is >= to the previous bid or != size ",
      %{book_pid: book_pid}
    ) do
      start_advisor!(MyAdvisor)

      snapshot = %Tai.Markets.OrderBook{
        bids: %{101.2 => {1.0, nil, nil}},
        asks: %{101.3 => {0.1, nil, nil}}
      }

      Tai.Markets.OrderBook.replace(book_pid, snapshot)

      assert_receive {
        :my_order_book_feed,
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
        ^snapshot,
        %Tai.Advisor{}
      }

      changes = %Tai.Markets.OrderBook{bids: %{101.2 => {1.1, nil, nil}}, asks: %{}}

      refute_receive {
        _feed_id,
        _symbol,
        _bid,
        _ask,
        _changes,
        %Tai.Advisor{}
      }

      Tai.Markets.OrderBook.update(book_pid, changes)

      assert_receive {
        :my_order_book_feed,
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
        ^changes,
        %Tai.Advisor{}
      }
    end

    test(
      "is called on broadcast changes when the inside ask price is <= to the previous ask or != size ",
      %{book_pid: book_pid}
    ) do
      start_advisor!(MyAdvisor)

      snapshot = %Tai.Markets.OrderBook{
        bids: %{101.2 => {1.0, nil, nil}},
        asks: %{101.3 => {0.1, nil, nil}}
      }

      Tai.Markets.OrderBook.replace(book_pid, snapshot)

      assert_receive {
        :my_order_book_feed,
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
        ^snapshot,
        %Tai.Advisor{}
      }

      changes = %Tai.Markets.OrderBook{bids: %{}, asks: %{101.3 => {0.2, nil, nil}}}

      refute_receive {
        _feed_id,
        _symbol,
        _bid,
        _ask,
        _changes,
        %Tai.Advisor{}
      }

      Tai.Markets.OrderBook.update(book_pid, changes)

      assert_receive {
        :my_order_book_feed,
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
        ^changes,
        %Tai.Advisor{}
      }
    end

    test("logs a warning message when it returns an unknown type", %{
      book_pid: book_pid
    }) do
      start_advisor!(MyAdvisor, %{return_val: {:unknown, :return_val}})

      log_msg =
        capture_log(fn ->
          snapshot = %Tai.Markets.OrderBook{bids: %{101.2 => {1.0, nil, nil}}, asks: %{}}
          Tai.Markets.OrderBook.replace(book_pid, snapshot)
          :timer.sleep(100)
        end)

      assert log_msg =~
               "[warn]  handle_inside_quote returned an invalid value: '{:unknown, :return_val}'"
    end

    test "can store data in state by returning an ok tuple", %{book_pid: book_pid} do
      start_advisor!(MyAdvisor, %{return_val: {:ok, %{hello: "world"}}})

      snapshot = %Tai.Markets.OrderBook{
        bids: %{101.2 => {1.0, nil, nil}},
        asks: %{101.3 => {0.1, nil, nil}}
      }

      Tai.Markets.OrderBook.replace(book_pid, snapshot)

      assert_receive {
        :my_order_book_feed,
        :btc_usd,
        %Tai.Markets.Quote{},
        ^snapshot,
        %Tai.Advisor{advisor_id: :my_advisor, store: %{return_val: {:ok, %{hello: "world"}}}}
      }

      changes = %Tai.Markets.OrderBook{bids: %{}, asks: %{101.3 => {0.2, nil, nil}}}
      Tai.Markets.OrderBook.update(book_pid, changes)

      assert_receive {
        :my_order_book_feed,
        :btc_usd,
        %Tai.Markets.Quote{},
        ^changes,
        %Tai.Advisor{advisor_id: :my_advisor, store: %{hello: "world"}}
      }
    end

    test "doesn't change store data state with an ok atom", %{book_pid: book_pid} do
      defmodule OkAdvisor do
        use Tai.Advisor

        def handle_inside_quote(feed_id, symbol, inside_quote, changes, state) do
          send(:test, {feed_id, symbol, inside_quote, changes, state})
          :ok
        end
      end

      start_advisor!(OkAdvisor, %{hello: "world"})

      snapshot = %Tai.Markets.OrderBook{
        bids: %{101.2 => {1.0, nil, nil}},
        asks: %{101.3 => {0.1, nil, nil}}
      }

      Tai.Markets.OrderBook.replace(book_pid, snapshot)

      assert_receive {
        :my_order_book_feed,
        :btc_usd,
        %Tai.Markets.Quote{},
        ^snapshot,
        %Tai.Advisor{advisor_id: :my_advisor, store: %{hello: "world"}}
      }

      changes = %Tai.Markets.OrderBook{bids: %{}, asks: %{101.3 => {0.2, nil, nil}}}
      Tai.Markets.OrderBook.update(book_pid, changes)

      assert_receive {
        :my_order_book_feed,
        :btc_usd,
        %Tai.Markets.Quote{},
        ^changes,
        %Tai.Advisor{advisor_id: :my_advisor, store: %{hello: "world"}}
      }
    end

    test("logs a warning message when an error is raised", %{
      book_pid: book_pid
    }) do
      start_advisor!(MyAdvisor, %{error: "!!!This is an ERROR!!!"})

      log_msg =
        capture_log(fn ->
          snapshot = %Tai.Markets.OrderBook{bids: %{101.2 => {1.0, nil, nil}}, asks: %{}}
          Tai.Markets.OrderBook.replace(book_pid, snapshot)
          :timer.sleep(100)
        end)

      assert log_msg =~
               "[warn]  handle_inside_quote raised an error: '%RuntimeError{message: \"!!!This is an ERROR!!!\"}', " <>
                 "stacktrace: [{Tai.Advisors.OrderBookCallbacksTest.MyAdvisor, :handle_inside_quote, 5, [file: 'test/tai/advisors/order_book_callbacks_test.exs', line:"
    end
  end
end
