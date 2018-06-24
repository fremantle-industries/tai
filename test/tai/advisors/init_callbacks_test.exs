defmodule Tai.Advisors.InitCallbacksTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Tai.TestSupport.Mock

  defmodule InitSuccessAdvisor do
    use Tai.Advisor

    def init_store(store) do
      new_store = Map.put(store, :init_store_callback, true)
      {:ok, new_store}
    end

    def handle_inside_quote(feed_id, symbol, inside_quote, changes, state) do
      send(:test, {feed_id, symbol, inside_quote, changes, state})
      :ok
    end
  end

  defmodule InitFailureAdvisor do
    use Tai.Advisor

    def init_store(_), do: :error

    def handle_inside_quote(feed_id, symbol, inside_quote, changes, state) do
      send(:test, {feed_id, symbol, inside_quote, changes, state})
      :ok
    end
  end

  setup do
    Process.register(self(), :test)

    :ok
  end

  describe "#init_store" do
    test "allows the store to be updated with an ok tuple" do
      start_supervised!({
        Tai.Markets.OrderBook,
        [
          feed_id: :init_success_feed,
          symbol: :btc_usd
        ]
      })

      start_supervised!({
        Tai.ExchangeAdapters.Mock.OrderBookFeed,
        [
          feed_id: :init_success_feed,
          symbols: [:btc_usd]
        ]
      })

      start_supervised!({
        InitSuccessAdvisor,
        [
          advisor_id: :init_success_advisor,
          order_books: %{init_success_feed: [:btc_usd]},
          accounts: [],
          store: %{}
        ]
      })

      mock_snapshot(
        :init_success_feed,
        :btc_usd,
        %{6500.1 => 1.1},
        %{6500.11 => 1.2}
      )

      assert_receive {
        :init_success_feed,
        :btc_usd,
        %Tai.Markets.Quote{},
        %Tai.Markets.OrderBook{},
        %Tai.Advisor{store: %{init_store_callback: true}}
      }
    end

    test "logs an error and uses the original store when not an ok tuple" do
      log_msg =
        capture_log(fn ->
          start_supervised!({
            Tai.Markets.OrderBook,
            [
              feed_id: :init_failure_feed,
              symbol: :btc_usd
            ]
          })

          start_supervised!({
            Tai.ExchangeAdapters.Mock.OrderBookFeed,
            [
              feed_id: :init_failure_feed,
              symbols: [:btc_usd]
            ]
          })

          start_supervised!({
            InitFailureAdvisor,
            [
              advisor_id: :init_failure_advisor,
              order_books: %{init_failure_feed: [:btc_usd]},
              accounts: [],
              store: %{}
            ]
          })

          mock_snapshot(
            :init_failure_feed,
            :btc_usd,
            %{6500.1 => 1.1},
            %{6500.11 => 1.2}
          )

          assert_receive {
            :init_failure_feed,
            :btc_usd,
            %Tai.Markets.Quote{},
            %Tai.Markets.OrderBook{},
            %Tai.Advisor{store: %{}}
          }
        end)

      assert log_msg =~ "[error] init_store must return {:ok, store} but it returned ':error'"
    end
  end
end
