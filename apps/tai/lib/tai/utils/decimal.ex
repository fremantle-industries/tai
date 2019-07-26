defmodule Tai.Utils.Decimal do
  @deprecated "Use Decimal.cast/1 instead."
  @spec from(number | String.t() | Decimal.t()) :: Decimal.t()
  def from(val) when is_float(val), do: Decimal.from_float(val)
  def from(val), do: Decimal.new(val)

  @spec round_up(Decimal.t(), Decimal.t()) :: Decimal.t()
  def round_up(val, increment) do
    d = :math.pow(10, abs(val.exp) - abs(increment.exp))
    v = ceil(val.coef / d)
    r = rem(v, increment.coef)

    z =
      if r == 0 do
        0
      else
        if val.sign > 0, do: increment.coef - r, else: -r
      end

    coef = v + z

    Decimal.new(val.sign, coef, increment.exp)
  end

  @spec round_down(Decimal.t(), Decimal.t()) :: Decimal.t()
  def round_down(val, increment) do
    d = :math.pow(10, abs(val.exp) - abs(increment.exp))
    v = trunc(val.coef / d)
    r = rem(v, increment.coef)

    z =
      if r == 0 do
        0
      else
        if val.sign > 0, do: -r, else: increment.coef - r
      end

    coef = v + z

    Decimal.new(val.sign, coef, increment.exp)
  end
end
