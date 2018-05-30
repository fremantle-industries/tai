defmodule Tai.Commands.Orders do
  @moduledoc """
  Display the list of orders and their details
  """

  alias TableRex.Table

  def orders do
    Tai.Trading.OrderStore.all()
    |> Enum.sort(&(DateTime.compare(&1.enqueued_at, &2.enqueued_at) == :lt))
    |> Enum.map(fn order ->
      [
        order.account_id,
        order.symbol,
        order.side,
        order.type,
        order.price,
        order.size,
        order.time_in_force,
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
    col_count = header() |> Enum.count()

    [List.duplicate("-", col_count)]
    |> print_table
  end

  defp print_table(rows) do
    rows
    |> Table.new(header())
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end

  defp header do
    [
      "Account",
      "Symbol",
      "Side",
      "Type",
      "Price",
      "Size",
      "Time in Force",
      "Status",
      "Client ID",
      "Server ID",
      "Enqueued At",
      "Created At"
    ]
  end
end
