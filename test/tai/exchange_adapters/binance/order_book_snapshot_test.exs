defmodule Tai.ExchangeAdapters.Binance.OrderBookSnapshotTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Binance.OrderBookSnapshot

  alias Tai.Markets.OrderBook
  alias Tai.ExchangeAdapters.Binance.OrderBookSnapshot

  setup_all do
    HTTPoison.start()
    start_supervised!({Tai.ExchangeAdapters.Gdax.Account, :my_gdax_exchange})

    :ok
  end

  test "fetch returns an ok, order book tuple" do
    use_cassette "exchange_adapters/binance/snapshot_ok" do
      assert {:ok, %OrderBook{bids: bids, asks: asks}} = OrderBookSnapshot.fetch(:ltcbtc, 5)

      assert %{
               0.018689 => {2.12, bid_processed_at_a, nil},
               0.018691 => {24.04, bid_processed_at_b, nil},
               0.0187 => {16.38, bid_processed_at_c, nil},
               0.018715 => {0.44, bid_processed_at_d, nil},
               0.01872 => {7.6, bid_processed_at_e, nil}
             } = bids

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
             } = asks

      assert DateTime.compare(ask_processed_at_a, ask_processed_at_b)
      assert DateTime.compare(ask_processed_at_a, ask_processed_at_c)
      assert DateTime.compare(ask_processed_at_a, ask_processed_at_d)
      assert DateTime.compare(ask_processed_at_a, ask_processed_at_e)
    end
  end

  test "fetch returns an error tuple when the symbol is invalid" do
    use_cassette "exchange_adapters/binance/snapshot_invalid_symbol_error" do
      assert {:error, :invalid_symbol} = OrderBookSnapshot.fetch(:idontexist, 5)
    end
  end
end
