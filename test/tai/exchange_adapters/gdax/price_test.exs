defmodule Tai.ExchangeAdapters.Gdax.PriceTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.ExchangeAdapters.Gdax.Price

  alias Tai.ExchangeAdapters.Gdax.Price

  setup_all do
    HTTPoison.start()
  end

  test "fetch returns value of the last trade for the symbol" do
    use_cassette "exchange_adapters/gdax/price_success" do
      assert Price.fetch(:btc_usd) == {:ok, Decimal.new("152.18000000")}
    end
  end

  test "fetch supports upper and lower case symbols" do
    use_cassette "exchange_adapters/gdax/price_success" do
      assert Price.fetch(:Btc_usD) == {:ok, Decimal.new("152.18000000")}
    end
  end

  test "fetch returns an error/message tuple when the symbol is not found" do
    use_cassette "exchange_adapters/gdax/price_not_found" do
      assert Price.fetch(:idontexist) == {:error, "not found"}
    end
  end
end
