defmodule Tai.Currencies.Bitcoin do
  def add(a, b) do
    to_satoshis(a) + to_satoshis(b)
    |> from_satoshis
  end

  def from_satoshis(satoshis) do
    satoshis / 10_000_000
  end

  def to_satoshis(btc) do
    btc * 10_000_000
  end
end
