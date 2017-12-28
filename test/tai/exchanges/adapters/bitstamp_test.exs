defmodule Tai.Exchanges.Adapters.BitstampTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Adapters.Bitstamp

  setup_all do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchanges/adapters/bitstamp")
  end

  test "price returns the value of the last trade for the symbol" do
    use_cassette "price_success" do
      assert Tai.Exchanges.Adapters.Bitstamp.price(:btcusd) == {:ok, Decimal.new(15243.98)}
    end
  end

  test "price supports upper and lower case symbols" do
    use_cassette "price_success" do
      assert Tai.Exchanges.Adapters.Bitstamp.price(:BtcusD) == {:ok, Decimal.new(15243.98)}
    end
  end

  test "price returns an error/message tuple when the symbol doesn't exist" do
    use_cassette "price_not_found" do
      assert Tai.Exchanges.Adapters.Bitstamp.price(:idontexist) == {:error, "not found"}
    end
  end

  test "quotes returns a bid/ask tuple for the given symbol" do
    use_cassette "quotes_success" do
      {:ok, bid, ask} = Tai.Exchanges.Adapters.Bitstamp.quotes(:btcusd)

      assert bid.size == Decimal.new(0.66809283)
      assert bid.price == Decimal.new("15378.00")
      assert ask.size == Decimal.new("0.96630000")
      assert ask.price == Decimal.new(15408.77)
    end
  end

  test "quotes returns an error tuple with a message when it can't find the symbol" do
    use_cassette "quotes_error" do
      assert Tai.Exchanges.Adapters.Bitstamp.quotes(:notfound) == {:error, "not found"}
    end
  end
end
