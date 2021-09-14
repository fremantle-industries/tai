defmodule Examples.PingPong.ManageQuoteChangeTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.{Advisor, Advisors, Markets, Venues}
  alias Examples.PingPong.ManageQuoteChange

  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @product_symbol :product_a

  setup do
    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  describe ".manage_entry_order/3" do
    test "cancels the open order when the inside quote price would change" do
      config = build_config()
      original_asks = [struct(Markets.PricePoint, price: 100.5)]
      original_market_quote = struct(Markets.Quote, asks: original_asks)
      original_market_quote_data = %{{@venue, @product_symbol} => original_market_quote}
      original_market_quotes = struct(Advisors.MarketMap, data: original_market_quote_data)

      {:ok, entry_order} = create_open_order(%{
        price: Decimal.new(100),
        qty: Decimal.new(1),
        leaves_qty: Decimal.new(1),
        cumulative_qty: Decimal.new(0)
      })

      state_1 =
        struct(Advisor.State,
          market_quotes: original_market_quotes,
          config: config,
          store: %{entry_order: entry_order}
        )

      assert {:ok, unchanged_run_store} =
               ManageQuoteChange.manage_entry_order(
                 {:ok, original_market_quote},
                 state_1
               )

      assert unchanged_run_store.entry_order.status == :open
      assert unchanged_run_store.entry_order.client_id == entry_order.client_id

      changed_asks = [struct(Markets.PricePoint, price: 120)]
      changed_market_quote = struct(Markets.Quote, asks: changed_asks)
      changed_market_quote_data = %{{@venue, @product_symbol} => changed_market_quote}
      changed_market_quotes = struct(Advisors.MarketMap, data: changed_market_quote_data)

      state_2 =
        struct(Advisor.State,
          market_quotes: changed_market_quotes,
          config: config,
          store: %{entry_order: entry_order}
        )

      assert {:ok, changed_run_store} =
               ManageQuoteChange.manage_entry_order(
                 {:ok, changed_market_quote},
                 state_2
               )

      assert changed_run_store.entry_order.status == :pending_cancel
      assert changed_run_store.entry_order.client_id == entry_order.client_id
    end
  end

  defp build_config do
    product = struct(Venues.Product, price_increment: Decimal.new("0.5"))
    fee = struct(Venues.FeeInfo, credential_id: :main)
    struct(Examples.PingPong.Config, product: product, fee: fee)
  end

  defp create_test_order(attrs) do
    %{
      venue: @venue |> Atom.to_string(),
      credential: @credential |> Atom.to_string(),
      product_symbol: @product_symbol |> Atom.to_string(),
      time_in_force: :gtc,
      type: :limit,
    }
    |> Map.merge(attrs)
    |> create_order_with_callback()
  end

  defp create_open_order(attrs) do
    %{status: :open}
    |> Map.merge(attrs)
    |> create_test_order()
  end
end
