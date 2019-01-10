defmodule Tai.Utils.Decimal do
  def from(val) when is_float(val), do: Decimal.from_float(val)
  def from(val), do: Decimal.new(val)
end
