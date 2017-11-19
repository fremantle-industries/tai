defmodule Tai.Currency do
  def add(a, b) do
    Decimal.add(a, b)
  end

  def sum(enumerable) do
    enumerable
    |> Enum.reduce(Decimal.new(0.0), &add/2)
  end
end
