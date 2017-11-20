defmodule Tai.Exchanges.Adapters.GdaxTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Adapters.Gdax

  setup_all do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchanges/adapters/gdax")
  end

  test "price returns value of the last trade for the pair" do
    use_cassette "price" do
      assert Tai.Exchanges.Adapters.Gdax.price(:btcusd) == Decimal.new(152.18)
    end
  end

  test "price supports upper and lower case symbols" do
    use_cassette "price" do
      assert Tai.Exchanges.Adapters.Gdax.price(:BtcusD) == Decimal.new(152.18)
    end
  end

  test "balance returns the USD sum of all accounts" do
    use_cassette "balance" do
      # 1337.247745066 USD
      # 1.1 BTC
      # 2.2 LTC
      # 3.3 ETH
      assert Tai.Exchanges.Adapters.Gdax.balance == Decimal.new(11503.403745066)
    end
  end

  test "quotes returns a bid/ask tuple for the given symbol" do
    use_cassette "quotes" do
      {bid, ask} = Tai.Exchanges.Adapters.Gdax.quotes(:btcusd)

      assert bid.size == Decimal.new(0.05)
      assert bid.price == Decimal.new(8015.01)
      assert ask.size == Decimal.new(4.222)
      assert ask.price == Decimal.new(8019.87)
    end
  end
end
