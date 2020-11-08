defmodule Tai.Markets.Asset do
  @moduledoc """
  Arbitratry precision arithmetic for assets
  """

  alias __MODULE__

  @type symbol :: atom
  @type t :: %Asset{val: Decimal.t(), symbol: symbol}

  @enforce_keys ~w(val symbol)a
  defstruct ~w(val symbol)a

  def new(val, symbol) do
    asset_val = val |> Tai.Utils.Decimal.cast!()
    %Asset{val: asset_val, symbol: symbol}
  end

  def add(%Asset{} = a, %Asset{} = b) do
    if a.symbol === b.symbol do
      new_val = Decimal.add(a.val, b.val)
      %Asset{val: new_val, symbol: a.symbol}
    else
      raise ArithmeticError, "can't add assets with different symbols: #{a.symbol}, #{b.symbol}"
    end
  end

  def sub(%Asset{} = a, %Asset{} = b) do
    if a.symbol === b.symbol do
      new_val = Decimal.sub(a.val, b.val)
      %Asset{val: new_val, symbol: a.symbol}
    else
      raise ArithmeticError,
            "can't subtract assets with different symbols: #{a.symbol}, #{b.symbol}"
    end
  end

  @zero Decimal.new(0)
  def zero?(%Asset{val: val}), do: val |> Decimal.compare(@zero) == :eq
end

defimpl String.Chars, for: Tai.Markets.Asset do
  alias Tai.Markets.Asset

  def to_string(%Asset{val: val, symbol: symbol}) do
    p = precision(symbol)

    val
    |> Decimal.round(p)
    |> Decimal.to_string(:normal)
  end

  @default_precision 8
  @precision %{
    eth: 18,
    usd: 2
  }
  defp precision(symbol) do
    @precision
    |> Map.get(symbol, @default_precision)
  end
end
