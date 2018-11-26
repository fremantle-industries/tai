defmodule Tai.Commands.Table do
  @spec render!([] | [...], header :: [String.t()]) :: no_return
  def render!(rows, header)

  def render!([], header) do
    col_count = header |> Enum.count()

    [List.duplicate("-", col_count)]
    |> render!(header)
  end

  def render!(rows, header) do
    rows
    |> TableRex.Table.new(header)
    |> TableRex.Table.put_column_meta(:all, align: :right)
    |> TableRex.Table.render!()
    |> IO.puts()

    IEx.dont_display_result()
  end
end
