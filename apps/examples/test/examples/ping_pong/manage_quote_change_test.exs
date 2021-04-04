defmodule Examples.PingPong.ManageQuoteChangeTest do
  use ExUnit.Case, async: true
  alias Examples.PingPong.ManageQuoteChange

  defmodule TestOrdersProvider do
    def cancel(order) do
      client_id = order.client_id |> String.duplicate(2)

      pending_cancel_order =
        struct(Tai.Orders.Order, client_id: client_id, status: :pending_cancel)

      {:ok, pending_cancel_order}
    end
  end

  describe ".manage_entry_order/3" do
    test "cancels the open order when the inside quote price would change" do
      product = struct(Tai.Venues.Product, price_increment: Decimal.new("0.5"))
      config = struct(Examples.PingPong.Config, product: product)

      market_quote =
        struct(Tai.Markets.Quote, asks: [struct(Tai.Markets.PricePoint, price: 100.5)])

      market_quotes =
        struct(Tai.Advisors.MarketQuotes, data: %{{:venue_a, :product_a} => market_quote})

      entry_order =
        struct(Tai.Orders.Order,
          client_id: "A",
          venue_id: :venue_a,
          product_symbol: :product_a,
          status: :open,
          price: Decimal.new(100)
        )

      state_1 =
        struct(Tai.Advisor.State,
          market_quotes: market_quotes,
          config: config,
          store: %{entry_order: entry_order}
        )

      assert {:ok, unchanged_run_store} =
               ManageQuoteChange.manage_entry_order(
                 {:ok, market_quote},
                 state_1,
                 TestOrdersProvider
               )

      assert unchanged_run_store.entry_order.status == :open
      assert unchanged_run_store.entry_order.client_id == "A"

      changed_market_quote =
        struct(Tai.Markets.Quote, asks: [struct(Tai.Markets.PricePoint, price: 120)])

      changed_market_quotes =
        struct(Tai.Advisors.MarketQuotes, data: %{{:venue_a, :product_a} => changed_market_quote})

      state_2 =
        struct(Tai.Advisor.State,
          market_quotes: changed_market_quotes,
          config: config,
          store: %{entry_order: entry_order}
        )

      assert {:ok, changed_run_store} =
               ManageQuoteChange.manage_entry_order(
                 {:ok, changed_market_quote},
                 state_2,
                 TestOrdersProvider
               )

      assert changed_run_store.entry_order.status == :pending_cancel
      assert changed_run_store.entry_order.client_id == "AA"
    end
  end
end
