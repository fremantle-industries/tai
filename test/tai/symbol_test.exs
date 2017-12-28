defmodule Tai.SymbolTest do
  use ExUnit.Case, async: true
  doctest Tai.Symbol

  test "downcase converts an atom to a downcased string" do
    assert Tai.Symbol.downcase(:FOO) == "foo"
  end

  test "downcase converts uppercase strings to downcase" do
    assert Tai.Symbol.downcase("FOO") == "foo"
  end
end
