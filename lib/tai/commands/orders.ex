defmodule Tai.Commands.Orders do
  alias Tai.Trading.Orders

  def orders do
    Orders.all
    |> Enum.sort(&DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt)
    |> Enum.map(fn order ->
      [
        order.exchange,
        order.symbol,
        order.price,
        order.size,
        order.client_id,
        order.server_id,
        Timex.from_now(order.enqueued_at),
        order.created_at && Timex.from_now(order.created_at)
      ]
    end)
    |> print_table
  end

  defp print_table(rows) do
    header = ["Exchange", "Symbol", "Price", "Size", "Client ID", "Server ID", "Enqueued At", "Created At"]

    TableRex.Table.new(rows, header)
    |> TableRex.Table.put_column_meta(:all, align: :right)
    |> TableRex.Table.render!
    |> IO.puts
  end
end
