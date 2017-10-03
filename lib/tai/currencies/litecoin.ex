defmodule Tai.Currencies.Litecoin do
  def add(a, b) do
    to_lits(a) + to_lits(b)
    |> from_lits
  end

  def from_lits(lits) do
    lits / 10_000_000
  end

  def to_lits(ltc) do
    ltc * 10_000_000
  end
end
