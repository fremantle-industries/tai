defmodule Tai.Markets.SymbolTest do
  use ExUnit.Case, async: true
  doctest Tai.Markets.Symbol

  describe "#downcase" do
    test "converts an atom to a downcase string" do
      assert Tai.Markets.Symbol.downcase(:FOO) == "foo"
    end

    test "converts an uppercase string to a downcase string" do
      assert Tai.Markets.Symbol.downcase("FOO") == "foo"
    end
  end

  describe "#downcase_all" do
    test "converts atoms to downcase strings" do
      assert Tai.Markets.Symbol.downcase_all([:FOO, :Bar]) == ["foo", "bar"]
    end

    test "converts uppercase strings to downcase strings" do
      assert Tai.Markets.Symbol.downcase_all(["FOO", "Bar"]) == ["foo", "bar"]
    end
  end

  describe "#upcase" do
    test "converts an atom to an uppercase string" do
      assert Tai.Markets.Symbol.upcase(:foo) == "FOO"
    end

    test "converts a downcase string to an uppercase string" do
      assert Tai.Markets.Symbol.upcase("foo") == "FOO"
    end
  end

  describe "#build" do
    test "returns a symbol for the base and quote asset separated by an underscore" do
      assert Tai.Markets.Symbol.build("btc", "usdt") == :btc_usdt
    end

    test "downcases the base and quote assets" do
      assert Tai.Markets.Symbol.build("BTC", "USDT") == :btc_usdt
    end
  end
end
