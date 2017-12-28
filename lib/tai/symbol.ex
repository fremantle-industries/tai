defmodule Tai.Symbol do
  def downcase(symbol) when is_atom(symbol), do: symbol |> Atom.to_string |> String.downcase
  def downcase(symbol), do: symbol |> String.downcase
end
