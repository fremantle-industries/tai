defmodule Tai.VenueAdapters.Binance.OrderBookFeed.SnapshotTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.VenueAdapters.Binance.OrderBookFeed.Snapshot

  alias Tai.VenueAdapters.Binance.OrderBookFeed

  setup_all do
    HTTPoison.start()
    :ok
  end

  test "fetch returns an ok, order book tuple" do
    use_cassette "exchange_adapters/binance/snapshot_ok" do
      assert {:ok, %Tai.Markets.OrderBook{} = order_book} =
               OrderBookFeed.Snapshot.fetch(:my_venue, :my_symbol, 5)

      assert order_book.venue_id == :my_venue
      assert order_book.product_symbol == :my_symbol

      assert %{
               0.018689 => {2.12, bid_processed_at_a, nil},
               0.018691 => {24.04, bid_processed_at_b, nil},
               0.0187 => {16.38, bid_processed_at_c, nil},
               0.018715 => {0.44, bid_processed_at_d, nil},
               0.01872 => {7.6, bid_processed_at_e, nil}
             } = order_book.bids

      assert DateTime.compare(bid_processed_at_a, bid_processed_at_b)
      assert DateTime.compare(bid_processed_at_a, bid_processed_at_c)
      assert DateTime.compare(bid_processed_at_a, bid_processed_at_d)
      assert DateTime.compare(bid_processed_at_a, bid_processed_at_e)

      assert %{
               0.018723 => {1.21, ask_processed_at_a, nil},
               0.018725 => {3.42, ask_processed_at_b, nil},
               0.018727 => {0.82, ask_processed_at_c, nil},
               0.018728 => {12.2, ask_processed_at_d, nil},
               0.018729 => {6.0, ask_processed_at_e, nil}
             } = order_book.asks

      assert DateTime.compare(ask_processed_at_a, ask_processed_at_b)
      assert DateTime.compare(ask_processed_at_a, ask_processed_at_c)
      assert DateTime.compare(ask_processed_at_a, ask_processed_at_d)
      assert DateTime.compare(ask_processed_at_a, ask_processed_at_e)
    end
  end

  test "fetch returns an error tuple when the symbol is invalid" do
    use_cassette "exchange_adapters/binance/snapshot_invalid_symbol_error" do
      assert {:error, :bad_symbol} = OrderBookFeed.Snapshot.fetch(:my_venue, :idontexist, 5)
    end
  end
end
