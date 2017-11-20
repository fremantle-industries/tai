defmodule Tai.SettingsTest do
  use ExUnit.Case
  doctest Tai.Settings

  test "exchange_ids returns the keys from exchanges" do
    assert Tai.Settings.exchange_ids == [:test_exchange_a, :test_exchange_b]
  end
end
