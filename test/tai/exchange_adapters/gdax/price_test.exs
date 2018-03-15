defmodule Tai.ExchangeAdapters.Gdax.PriceTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Gdax.Price

  alias Tai.ExchangeAdapters.Gdax.Price

  setup_all do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchanges/adapters/gdax")
  end

  test "fetch returns value of the last trade for the symbol" do
    use_cassette "price_success" do
      assert Price.fetch(:btcusd) == {:ok, Decimal.new("152.18000000")}
    end
  end

  test "fetch supports upper and lower case symbols" do
    use_cassette "price_success" do
      assert Price.fetch(:BtcusD) == {:ok, Decimal.new("152.18000000")}
    end
  end

  test "fetch returns an error/message tuple when the symbol is not found" do
    use_cassette "price_not_found" do
      assert Price.fetch(:idontexist) == {:error, "not found"}
    end
  end
end