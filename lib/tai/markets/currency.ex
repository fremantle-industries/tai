defmodule Tai.Markets.Currency do
  def add(a, b) do
    Decimal.add(
      Decimal.new(a),
      Decimal.new(b)
    )
  end

  def sum(enumerable) do
    enumerable
    |> Enum.reduce(Decimal.new(0.0), &add/2)
  end
end
