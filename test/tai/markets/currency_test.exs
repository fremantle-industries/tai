defmodule Tai.Markets.CurrencyTest do
  use ExUnit.Case, async: true
  doctest Tai.Markets.Currency

  alias Tai.Markets.Currency

  test "adds 2 decimals together and returns a decimal" do
    assert Currency.add(Decimal.new(1.1), Decimal.new(2.2)) == Decimal.new(3.3)
  end

  test "adds a float and a decimal together and returns a decimal" do
    assert Currency.add(1.1, Decimal.new(2.2)) == Decimal.new(3.3)
  end

  test "adds a decimal and a float together and returns a decimal" do
    assert Currency.add(Decimal.new(1.1), 2.2) == Decimal.new(3.3)
  end

  test "adds an integer and a decimal together and returns a decimal" do
    assert Currency.add(1, Decimal.new(2.2)) == Decimal.new(3.2)
  end

  test "adds a decimal and an integer together and returns a decimal" do
    assert Currency.add(Decimal.new(1.1), 2) == Decimal.new(3.1)
  end

  test "sums an enumerable of numbers and returns a decimal" do
    assert Currency.sum([1.1, 2, Decimal.new(3.3)]) == Decimal.new(6.4)
  end
end
