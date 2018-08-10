defmodule Tai.Commands.Settings do
  alias TableRex.Table

  def settings do
    Tai.Settings.all()
    |> Enum.map(&Tuple.to_list/1)
    |> render!
  end

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
