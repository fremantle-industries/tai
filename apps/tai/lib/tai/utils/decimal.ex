defmodule Tai.Utils.Decimal do
  @deprecated "Use Decimal.cast/1 instead."
  @spec from(number | String.t() | Decimal.t()) :: Decimal.t()
  def from(val) when is_float(val), do: Decimal.from_float(val)
  def from(val), do: Decimal.new(val)

  @spec round_up(Decimal.t(), Decimal.t()) :: Decimal.t()
  def round_up(val, increment) do
    {vc, ic, e} = same_order_of(val, increment)
    r = rem(vc, ic)

    if val.sign == 1 and r > 0 do
      v = vc + (ic - r)
      Decimal.new(val.sign, v, e)
    else
      v = vc - r
      Decimal.new(val.sign, v, e)
    end
  end

  @spec round_down(Decimal.t(), Decimal.t()) :: Decimal.t()
  def round_down(val, increment) do
    {vc, ic, e} = same_order_of(val, increment)
    r = rem(vc, ic)

    if val.sign == 1 or r == 0 do
      v = vc - r
      Decimal.new(val.sign, v, e)
    else
      v = vc + (ic - r)
      Decimal.new(val.sign, v, e)
    end
  end

  defp same_order_of(val, increment) do
    cond do
      val.exp < increment.exp ->
        s = abs(val.exp - increment.exp)
        ic = trunc(:math.pow(10, s)) * increment.coef
        {val.coef, ic, val.exp}

      increment.exp < val.exp ->
        s = abs(increment.exp - val.exp)
        vc = trunc(:math.pow(10, s)) * val.coef
        {vc, increment.coef, increment.exp}

      true ->
        {val.coef, increment.coef, val.exp}
    end
  end
end
