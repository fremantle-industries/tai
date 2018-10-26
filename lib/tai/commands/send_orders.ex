defmodule Tai.Commands.SendOrders do
  alias TableRex.Table

  require Logger

  @spec disable :: no_return
  def disable do
    Tai.Settings.disable_send_orders!()
    rows() |> render!()
  end

  @spec enable :: no_return
  def enable do
    Tai.Settings.enable_send_orders!()
    rows() |> render!()
  end

  defp rows do
    Tai.Settings.all()
    |> Map.to_list()
    |> Enum.filter(fn {k, _} -> k == :send_orders end)
    |> Enum.map(&Tuple.to_list/1)
  end

  @headers ["Name", "Value"]
  @spec render!(rows :: [...]) :: no_return
  defp render!(rows) do
    rows
    |> Table.new(@headers)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
