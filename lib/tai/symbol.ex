defmodule Tai.Symbol do
  @moduledoc """
  Transform symbols between tai and exchange formats
  """

  def downcase(symbol) when is_atom(symbol) do
    symbol
    |> Atom.to_string()
    |> String.downcase()
  end

  def downcase(symbol) do
    symbol
    |> String.downcase()
  end

  def downcase_all(symbols) do
    symbols
    |> Enum.map(&downcase(&1))
  end

  def upcase(symbol) when is_atom(symbol) do
    symbol
    |> Atom.to_string()
    |> String.upcase()
  end

  def upcase(symbol) do
    symbol
    |> String.upcase()
  end

  @spec build(String.t(), String.t()) :: atom
  def build(base_asset, quote_asset)
      when is_binary(base_asset) and is_binary(quote_asset) do
    "#{base_asset}_#{quote_asset}"
    |> String.downcase()
    |> String.to_atom()
  end
end
