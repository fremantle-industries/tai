defmodule Tai.SettingsTest do
  use ExUnit.Case
  doctest Tai.Settings

  test "accounts returns the application config" do
    assert Tai.Settings.accounts == %{
      test_account_a: [
        Tai.Adapters.Test
      ],
      test_account_b: [
        Tai.Adapters.Test,
        config_key: "some_key"
      ]
    }
  end

  test "account_ids returns the keys from accounts" do
    assert Tai.Settings.account_ids == [:test_account_a, :test_account_b]
  end
end
