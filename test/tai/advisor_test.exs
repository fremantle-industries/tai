defmodule Tai.AdvisorTest do
  use ExUnit.Case, async: true
  doctest Tai.Advisor

  alias Tai.{Advisor, PubSub}

  defmodule MyAdvisor do
    use Advisor

    def handle_quotes(state, feed_id, symbol, changes) do
      send :test, {state, feed_id, symbol, changes}
    end
  end

  setup do
    Process.register self(), :test
    start_supervised!({MyAdvisor, :my_advisor})

    :ok
  end

  test "executes the handle_quotes callback with the changes" do
    PubSub.broadcast(
      :order_book,
      {
        :quotes,
        :test_feed,
        :btcusd,
        [[side: :bid, price: 101.1, size: 1.1]]
      }
    )

    assert_receive {
      %{advisor_id: :my_advisor},
      :test_feed,
      :btcusd,
      [[side: :bid, price: 101.1, size: 1.1]]
    }
  end
end
