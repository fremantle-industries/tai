defmodule Tai.Exchanges.ConfigTest do
  use ExUnit.Case, async: true
  doctest Tai.Exchanges.Config

  describe "#all" do
    test "products is '*' when not provided" do
      exchanges = %{a: [supervisor: Tai.ExchangeAdapters.Test.Supervisor]}

      assert [%Tai.Exchanges.Config{} = config] = Tai.Exchanges.Config.all(exchanges)
      assert config.products == "*"
    end

    test "products can be provided" do
      exchanges = %{
        a: [supervisor: Tai.ExchangeAdapters.Test.Supervisor, products: "btc_usdt"]
      }

      assert [%Tai.Exchanges.Config{} = config] = Tai.Exchanges.Config.all(exchanges)
      assert config.products == "btc_usdt"
    end
  end
end
