defmodule Tai.Commands.NewBalances do
  @moduledoc """
  Display symbols on each exchange with a non-zero balance
  """

  alias TableRex.Table

  def new_balance do
    header = [
      "Exchange",
      "Symbol",
      "Total",
      "Tradeable"
    ]

    rows = []

    rows
    |> Table.new(header)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
