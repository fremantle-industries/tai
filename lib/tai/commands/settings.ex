defmodule Tai.Commands.Settings do
  alias TableRex.Table

  @spec settings :: no_return
  def settings do
    Tai.Settings.all()
    |> Map.to_list()
    |> Enum.filter(fn {k, _} -> k != :__struct__ end)
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&format_col/1)
    |> render!
  end

  def format_col(val) when is_boolean(val), do: val |> to_string()
  def format_col(val) when is_atom(val), do: val |> Atom.to_string()
  def format_col(val), do: val

  @headers ["Name", "Value"]
  @spec render!(list) :: no_return
  defp render!(rows) do
    rows
    |> Table.new(@headers)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
