defmodule Tai.ExchangeAdapters.Binance.SymbolMapping do
  @spec to_binance(atom) :: String.t()
  def to_binance(symbol) do
    symbol
    |> Atom.to_string()
    |> String.replace("_", "")
    |> String.upcase()
  end

  @spec to_tai(String.t()) :: atom
  def to_tai(pair) do
    pair
    |> String.reverse()
    |> insert_split
    |> String.downcase()
    |> String.reverse()
    |> String.to_atom()
  end

  defp insert_split("CTB" <> base), do: "CTB_#{base}"
  defp insert_split("HTE" <> base), do: "HTE_#{base}"
  defp insert_split("BNB" <> base), do: "BNB_#{base}"
  defp insert_split("TDSU" <> base), do: "TDSU_#{base}"

  defp insert_split(other), do: other
end
