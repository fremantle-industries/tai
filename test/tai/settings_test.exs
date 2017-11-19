defmodule Tai.SettingsTest do
  use ExUnit.Case
  doctest Tai.Settings

  test "exchanges returns the application config" do
    assert Tai.Settings.exchanges == %{
      test_exchange_a: [
        Tai.Exchanges.Adapters.Test
      ],
      test_exchange_b: [
        Tai.Exchanges.Adapters.Test,
        config_key: "some_key"
      ]
    }
  end

  test "exchange_ids returns the keys from exchanges" do
    assert Tai.Settings.exchange_ids == [:test_exchange_a, :test_exchange_b]
  end
end
