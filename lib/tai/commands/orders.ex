defmodule Tai.Commands.Orders do
  alias Tai.Trading.Orders

  def orders do
    Orders.all()
    |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))
    |> Enum.map(fn order ->
      [
        order.exchange,
        order.symbol,
        order.type,
        order.price,
        order.size,
        order.status,
        order.client_id,
        order.server_id,
        Timex.from_now(order.enqueued_at),
        order.created_at && Timex.from_now(order.created_at)
      ]
    end)
    |> print_table
  end

  defp print_table([]) do
    [
      "-"
      |> List.duplicate(header() |> Enum.count())
    ]
    |> print_table
  end

  defp print_table(rows) do
    TableRex.Table.new(rows, header())
    |> TableRex.Table.put_column_meta(:all, align: :right)
    |> TableRex.Table.render!()
    |> IO.puts()
  end

  defp header do
    [
      "Exchange",
      "Symbol",
      "Type",
      "Price",
      "Size",
      "Status",
      "Client ID",
      "Server ID",
      "Enqueued At",
      "Created At"
    ]
  end
end
