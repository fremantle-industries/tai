defmodule Tai.IEx.Commands.SendOrders do
  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header ["Name", "Value"]

  @spec disable :: no_return
  def disable do
    Tai.Settings.disable_send_orders!()

    rows()
    |> render!(@header)
  end

  @spec enable :: no_return
  def enable do
    Tai.Settings.enable_send_orders!()

    rows()
    |> render!(@header)
  end

  defp rows do
    Tai.Settings.all()
    |> Map.to_list()
    |> Enum.filter(fn {k, _} -> k == :send_orders end)
    |> Enum.map(&Tuple.to_list/1)
  end
end
