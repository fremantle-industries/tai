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

  def base_and_quote(symbol) when is_binary(symbol) do
    assets = String.split(symbol, "_")
    assets_count = Enum.count(assets)

    if assets_count == 2 do
      [base_asset, quote_asset] = Enum.map(assets, &String.to_atom/1)
      {:ok, {base_asset, quote_asset}}
    else
      {:error, :symbol_format_must_be_base_quote}
    end
  end

  def base_and_quote(symbol) when is_atom(symbol) do
    symbol
    |> Atom.to_string()
    |> base_and_quote
  end

  def base_and_quote(_), do: {:error, :symbol_must_be_an_atom_or_string}
end
