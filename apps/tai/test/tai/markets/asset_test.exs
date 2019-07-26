defmodule Tai.Markets.AssetTest do
  use ExUnit.Case, async: true
  doctest Tai.Markets.Asset

  alias Tai.Markets.Asset

  test "adds assets with the same symbol" do
    btc_1 = Asset.new(1.1, :btc)
    btc_2 = Asset.new(1.2, :btc)

    assert Asset.add(btc_1, btc_2) == Asset.new(2.3, :btc)
  end

  test "add raises an error when the symbols are different" do
    btc = Asset.new(1.1, :btc)
    ltc = Asset.new(0.2, :ltc)

    assert_raise ArithmeticError, "can't add assets with different symbols: btc, ltc", fn ->
      Asset.add(btc, ltc)
    end
  end

  test "subtracts assets with the same symbol" do
    btc_1 = Asset.new(1.1, :btc)
    btc_2 = Asset.new(0.2, :btc)

    assert Asset.sub(btc_1, btc_2) == Asset.new(0.9, :btc)
  end

  test "sub raises an error when the symbols are different" do
    btc = Asset.new(1.1, :btc)
    ltc = Asset.new(0.2, :ltc)

    assert_raise ArithmeticError, "can't subtract assets with different symbols: btc, ltc", fn ->
      Asset.sub(btc, ltc)
    end
  end

  test "zero? returns true when the decimal comparison to 0 is :eq" do
    assert 0 |> Asset.new(:btc) |> Asset.zero?() == true
    assert 0.0 |> Asset.new(:btc) |> Asset.zero?() == true
    assert "0" |> Asset.new(:btc) |> Asset.zero?() == true
    assert "0.0" |> Asset.new(:btc) |> Asset.zero?() == true
    assert "0.00000001" |> Asset.new(:btc) |> Asset.zero?() == false
    assert "0.000000001" |> Asset.new(:btc) |> Asset.zero?() == false
    assert 1.1 |> Asset.new(:btc) |> Asset.zero?() == false
  end

  test "implements String.Chars protocol where to_string rounds the assets to their maximum precision" do
    assert "#{0.00001 |> Asset.new(:btc)}" == "0.00001000"
    assert "#{1.1 |> Asset.new(:ltc)}" == "1.10000000"
    assert "#{0.000000000011 |> Asset.new(:eth)}" == "0.000000000011000000"
    assert "#{1.1 |> Asset.new(:idontexist)}" == "1.10000000"
  end
end
