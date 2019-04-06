defmodule Tai.Utils.DecimalTest do
  use ExUnit.Case, async: true
  doctest Tai.Utils.Decimal

  describe ".from/1" do
    test "returns a decimal from and integer, float, string or decimal" do
      assert Tai.Utils.Decimal.from(1) == Decimal.new(1)
      assert Tai.Utils.Decimal.from(1.1) == Decimal.new("1.1")
      assert Tai.Utils.Decimal.from("1.2") == Decimal.new("1.2")
      assert Tai.Utils.Decimal.from(Decimal.new("1.3")) == Decimal.new("1.3")
    end
  end

  describe ".round_up/2" do
    test "rounds the value up to the nearest increment" do
      assert Tai.Utils.Decimal.round_up(Decimal.new("3001.700"), Decimal.new("0.5")) ==
               Decimal.new("3002.0")

      assert Tai.Utils.Decimal.round_up(Decimal.new("3001.002"), Decimal.new("0.5")) ==
               Decimal.new("3001.5")

      assert Tai.Utils.Decimal.round_up(Decimal.new("3001.5"), Decimal.new("0.50")) ==
               Decimal.new("3001.50")

      assert Tai.Utils.Decimal.round_up(Decimal.new("3001"), Decimal.new("0.500")) ==
               Decimal.new("3001.000")

      assert Tai.Utils.Decimal.round_up(Decimal.new("3001.71"), Decimal.new("0.02")) ==
               Decimal.new("3001.72")

      assert Tai.Utils.Decimal.round_up(Decimal.new("-3001.700"), Decimal.new("0.5")) ==
               Decimal.new("-3001.5")

      assert Tai.Utils.Decimal.round_up(Decimal.new("-3001.5"), Decimal.new("0.50")) ==
               Decimal.new("-3001.50")

      assert Tai.Utils.Decimal.round_up(Decimal.new("-3001"), Decimal.new("0.500")) ==
               Decimal.new("-3001.000")

      assert Tai.Utils.Decimal.round_up(Decimal.new("-3001.71"), Decimal.new("0.02")) ==
               Decimal.new("-3001.70")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00001")
             ) ==
               Decimal.new("0.03566")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00002")
             ) ==
               Decimal.new("0.03566")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00003")
             ) ==
               Decimal.new("0.03567")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00004")
             ) ==
               Decimal.new("0.03568")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00005")
             ) ==
               Decimal.new("0.03570")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00007")
             ) ==
               Decimal.new("0.03570")
    end
  end

  describe ".round_down/2" do
    test "rounds the value down to the nearest increment" do
      assert Tai.Utils.Decimal.round_down(Decimal.new("3001.700"), Decimal.new("0.5")) ==
               Decimal.new("3001.5")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001.002"), Decimal.new("0.5")) ==
               Decimal.new("3001.0")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001.5"), Decimal.new("0.50")) ==
               Decimal.new("3001.50")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001"), Decimal.new("0.500")) ==
               Decimal.new("3001.000")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001.71"), Decimal.new("0.02")) ==
               Decimal.new("3001.70")

      assert Tai.Utils.Decimal.round_down(Decimal.new("-3001.700"), Decimal.new("0.5")) ==
               Decimal.new("-3002.0")

      assert Tai.Utils.Decimal.round_down(Decimal.new("-3001.5"), Decimal.new("0.50")) ==
               Decimal.new("-3001.50")

      assert Tai.Utils.Decimal.round_down(Decimal.new("-3001"), Decimal.new("0.500")) ==
               Decimal.new("-3001.000")

      assert Tai.Utils.Decimal.round_down(Decimal.new("-3001.71"), Decimal.new("0.02")) ==
               Decimal.new("-3001.72")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00001")
             ) ==
               Decimal.new("0.03565")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00002")
             ) ==
               Decimal.new("0.03564")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00003")
             ) ==
               Decimal.new("0.03564")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00005")
             ) ==
               Decimal.new("0.03565")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.03565503620803159973666886109"),
               Decimal.new("0.00007")
             ) ==
               Decimal.new("0.03563")
    end
  end
end
