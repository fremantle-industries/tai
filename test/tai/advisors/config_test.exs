defmodule Tai.Advisors.ConfigTest do
  use ExUnit.Case
  doctest Tai.Advisors.Config

  test "all returns the application config" do
    assert Tai.Advisors.Config.all == %{
      test_advisor_a: Support.Advisors.SpreadCapture,
      test_advisor_b: Support.Advisors.SpreadCapture
    }
  end

  test "all returns an empty map when no advisors have been configured" do
    assert Tai.Advisors.Config.all(nil) == %{}
  end
end
