defmodule Tai.Commands.Fees do
  @moduledoc """
  Display the list of maker/taker fees for tradable products
  """

  alias TableRex.Table

  @spec fees :: no_return
  def fees do
    Tai.Exchanges.FeeStore.all()
    |> Enum.sort(&(&1.exchange_id < &2.exchange_id))
    |> format_rows
    |> render!
  end

  defp format_rows(fees) do
    fees
    |> Enum.map(fn fee_info ->
      [
        fee_info.exchange_id,
        fee_info.account_id,
        fee_info.symbol,
        {fee_info.maker, fee_info.maker_type},
        {fee_info.taker, fee_info.taker_type}
      ]
      |> Enum.map(&format_col/1)
    end)
  end

  defp format_col({val, :percent}) do
    percent =
      val
      |> Decimal.mult(Decimal.new(100))
      |> Decimal.reduce()
      |> Decimal.to_string(:normal)

    "#{percent}%"
  end

  defp format_col({val, _type}) do
    val
    |> Decimal.reduce()
    |> Decimal.to_string(:normal)
  end

  defp format_col(val), do: val

  @header [
    "Exchange ID",
    "Account ID",
    "Symbol",
    "Maker",
    "Taker"
  ]
  @spec render!(list) :: no_return
  defp render!(rows)

  defp render!([]) do
    col_count = @header |> Enum.count()

    [List.duplicate("-", col_count)]
    |> render!
  end

  defp render!(rows) do
    rows
    |> Table.new(@header)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end
end
