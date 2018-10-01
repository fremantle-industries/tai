defmodule Tai.Commands.Products do
  @moduledoc """
  Display the list of products and their trade requirements for each exchange
  """

  alias TableRex.Table

  @spec products :: no_return
  def products do
    Tai.Exchanges.ProductStore.all()
    |> Enum.sort(&(&1.symbol < &2.symbol))
    |> format_rows
    |> render!
  end

  defp format_rows(products) do
    products
    |> Enum.map(fn product ->
      [
        product.exchange_id,
        product.symbol,
        product.exchange_symbol,
        product.status,
        product.min_price,
        product.max_price,
        product.price_increment,
        product.min_size,
        product.max_size,
        product.size_increment,
        product.min_notional
      ]
      |> Enum.map(&format_col/1)
    end)
  end

  defp format_col(%Decimal{} = val) do
    val
    |> Decimal.reduce()
    |> Decimal.to_string(:normal)
  end

  defp format_col(val), do: val

  @header [
    "Exchange ID",
    "Symbol",
    "Exchange Symbol",
    "Status",
    "Min Price",
    "Max Price",
    "Price Increment",
    "Min Size",
    "Max Size",
    "Size Increment",
    "Min Notional"
  ]
  @spec render!(rows :: []) :: no_return
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
