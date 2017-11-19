defmodule Tai.Exchanges.Adapters.GdaxTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Tai.Exchanges.Adapters.Gdax

  setup_all do
    HTTPoison.start
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes/exchanges/adapters/gdax")
  end

  test "balance returns the USD sum of all accounts" do
    use_cassette "balance" do
      assert Tai.Exchanges.Adapters.Gdax.balance == Decimal.new(1337.247745066)
    end
  end
end
