defmodule Tai.IEx.Commands.Settings do
  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header ["Name", "Value"]

  @spec settings :: no_return
  def settings do
    Tai.Commander.settings()
    |> Map.to_list()
    |> Enum.filter(fn {k, _} -> k != :__struct__ end)
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&format_col/1)
    |> render!(@header)
  end

  def format_col(val) when is_boolean(val), do: val |> to_string()
  def format_col(val) when is_atom(val), do: val |> Atom.to_string()
  def format_col(val), do: val
end
