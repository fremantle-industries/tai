defmodule Tai.ExchangeAdapters.Bitstamp.PriceTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Bitstamp.Price

  alias Tai.ExchangeAdapters.Bitstamp.Price

  setup_all do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchanges/adapters/bitstamp")

    :ok
  end

  test "fetch returns the value of the last trade for the symbol" do
    use_cassette "price_success" do
      assert Price.fetch(:btcusd) == {:ok, Decimal.new(15243.98)}
    end
  end

  test "fetch supports upper and lower case symbols" do
    use_cassette "price_success" do
      assert Price.fetch(:BtcusD) == {:ok, Decimal.new(15243.98)}
    end
  end

  test "fetch returns an error/message tuple when the symbol doesn't exist" do
    use_cassette "price_not_found" do
      assert Price.fetch(:idontexist) == {:error, "not found"}
    end
  end
end
