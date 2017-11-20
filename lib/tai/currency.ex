defmodule Tai.Currency do
  def parse!(val) do
    val
    |> Float.parse
    |> case do
      {parsed, _remainder} -> Decimal.new(parsed)
    end
  end

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
