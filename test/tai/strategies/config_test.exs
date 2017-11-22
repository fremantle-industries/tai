defmodule Tai.Strategies.ConfigTest do
  use ExUnit.Case
  doctest Tai.Strategies.Config

  test "all returns the application config" do
    assert Tai.Strategies.Config.all == %{
      test_strategy_a: Tai.Strategies.Info,
      test_strategy_b: Tai.Strategies.Info
    }
  end

  test "all returns an empty map when no strategies have been configured" do
    assert Tai.Strategies.Config.all(nil) == %{}
  end
end
