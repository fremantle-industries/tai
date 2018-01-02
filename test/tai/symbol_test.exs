defmodule Tai.SymbolTest do
  use ExUnit.Case, async: true
  doctest Tai.Symbol

  test "downcase converts an atom to a downcased string" do
    assert Tai.Symbol.downcase(:FOO) == "foo"
  end

  test "downcase convert an uppercase string to downcase" do
    assert Tai.Symbol.downcase("FOO") == "foo"
  end

  test "downcase_all converts atoms to downcased strings" do
    assert Tai.Symbol.downcase_all([:FOO, :Bar]) == ["foo", "bar"]
  end

  test "downcase_all converts uppercase strings to downcase" do
    assert Tai.Symbol.downcase_all(["FOO", "Bar"]) == ["foo", "bar"]
  end
end
