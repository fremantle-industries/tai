defmodule Tai.Utils.DecimalTest do
  use ExUnit.Case, async: true
  doctest Tai.Utils.Decimal

  describe ".round_up/2" do
    test "rounds the value up to the nearest increment" do
      assert Tai.Utils.Decimal.round_up(Decimal.new("3001.700"), Decimal.new("0.5")) ==
               Decimal.new("3002.000")

      assert Tai.Utils.Decimal.round_up(Decimal.new("3001.002"), Decimal.new("0.5")) ==
               Decimal.new("3001.500")

      assert Tai.Utils.Decimal.round_up(Decimal.new("3001.5"), Decimal.new("0.50")) ==
               Decimal.new("3001.50")

      assert Tai.Utils.Decimal.round_up(Decimal.new("3001"), Decimal.new("0.500")) ==
               Decimal.new("3001.000")

      assert Tai.Utils.Decimal.round_up(Decimal.new("3001.71"), Decimal.new("0.02")) ==
               Decimal.new("3001.72")

      assert Tai.Utils.Decimal.round_up(Decimal.new("-3001.700"), Decimal.new("0.5")) ==
               Decimal.new("-3001.500")

      assert Tai.Utils.Decimal.round_up(Decimal.new("-3001.5"), Decimal.new("0.50")) ==
               Decimal.new("-3001.50")

      assert Tai.Utils.Decimal.round_up(Decimal.new("-3001"), Decimal.new("0.500")) ==
               Decimal.new("-3001.000")

      assert Tai.Utils.Decimal.round_up(Decimal.new("-3001.71"), Decimal.new("0.02")) ==
               Decimal.new("-3001.70")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00001")
             ) ==
               Decimal.new("0.035660000000000000000000000")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00002")
             ) ==
               Decimal.new("0.035660000000000000000000000")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00003")
             ) ==
               Decimal.new("0.035670000000000000000000000")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00004")
             ) ==
               Decimal.new("0.035680000000000000000000000")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00005")
             ) ==
               Decimal.new("0.035700000000000000000000000")

      assert Tai.Utils.Decimal.round_up(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00007")
             ) ==
               Decimal.new("0.035700000000000000000000000")
    end
  end

  describe ".round_down/2" do
    test "rounds the value down to the nearest increment" do
      assert Tai.Utils.Decimal.round_down(Decimal.new(10), Decimal.new("0.00001")) ==
               Decimal.new("10.00000")

      assert Tai.Utils.Decimal.round_down(Decimal.new("10.0"), Decimal.new("0.00001")) ==
               Decimal.new("10.00000")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001.700"), Decimal.new("0.5")) ==
               Decimal.new("3001.500")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001.002"), Decimal.new("0.5")) ==
               Decimal.new("3001.000")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001.5"), Decimal.new("0.50")) ==
               Decimal.new("3001.50")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001"), Decimal.new("0.500")) ==
               Decimal.new("3001.000")

      assert Tai.Utils.Decimal.round_down(Decimal.new("3001.71"), Decimal.new("0.02")) ==
               Decimal.new("3001.70")

      assert Tai.Utils.Decimal.round_down(Decimal.new("-3001.700"), Decimal.new("0.5")) ==
               Decimal.new("-3002.000")

      assert Tai.Utils.Decimal.round_down(Decimal.new("-3001.5"), Decimal.new("0.50")) ==
               Decimal.new("-3001.50")

      assert Tai.Utils.Decimal.round_down(Decimal.new("-3001"), Decimal.new("0.500")) ==
               Decimal.new("-3001.000")

      assert Tai.Utils.Decimal.round_down(Decimal.new("-3001.71"), Decimal.new("0.02")) ==
               Decimal.new("-3001.72")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00001")
             ) ==
               Decimal.new("0.035650000000000000000000000")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00002")
             ) ==
               Decimal.new("0.035640000000000000000000000")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00003")
             ) ==
               Decimal.new("0.035640000000000000000000000")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00005")
             ) ==
               Decimal.new("0.035650000000000000000000000")

      assert Tai.Utils.Decimal.round_down(
               Decimal.new("0.035655036208031599736668861"),
               Decimal.new("0.00007")
             ) ==
               Decimal.new("0.035630000000000000000000000")
    end
  end
end
