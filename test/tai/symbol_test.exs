defmodule Tai.SymbolTest do
  use ExUnit.Case, async: true
  doctest Tai.Symbol

  describe ".downcase" do
    test "converts an atom to a downcase string" do
      assert Tai.Symbol.downcase(:FOO) == "foo"
    end

    test "converts an uppercase string to a downcase string" do
      assert Tai.Symbol.downcase("FOO") == "foo"
    end
  end

  describe ".downcase_all" do
    test "converts atoms to downcase strings" do
      assert Tai.Symbol.downcase_all([:FOO, :Bar]) == ["foo", "bar"]
    end

    test "converts uppercase strings to downcase strings" do
      assert Tai.Symbol.downcase_all(["FOO", "Bar"]) == ["foo", "bar"]
    end
  end

  describe ".upcase" do
    test "converts an atom to an uppercase string" do
      assert Tai.Symbol.upcase(:foo) == "FOO"
    end

    test "converts a downcase string to an uppercase string" do
      assert Tai.Symbol.upcase("foo") == "FOO"
    end
  end

  describe ".build" do
    test "returns a symbol for the base and quote asset separated by an underscore" do
      assert Tai.Symbol.build("btc", "usdt") == :btc_usdt
    end

    test "downcases the base and quote assets" do
      assert Tai.Symbol.build("BTC", "USDT") == :btc_usdt
    end
  end

  describe ".base_and_quote" do
    test "returns the base and quote asset in an ok tuple" do
      assert Tai.Symbol.base_and_quote(:btc_usdt) == {:ok, {:btc, :usdt}}
      assert Tai.Symbol.base_and_quote("btc_usdt") == {:ok, {:btc, :usdt}}
    end

    test "returns an error tuple when the symbol is not an atom" do
      assert Tai.Symbol.base_and_quote(10) == {:error, :symbol_must_be_an_atom_or_string}
    end

    test "returns an error tuple when the symbol isn't 2 assets separated by an _" do
      assert Tai.Symbol.base_and_quote(:btc_ltc_eth) ==
               {:error, :symbol_format_must_be_base_quote}
    end
  end
end
