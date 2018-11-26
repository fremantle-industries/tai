defmodule Tai.Commands.Products do
  @moduledoc """
  Display the list of products and their trade requirements for each exchange
  """

  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Exchange ID",
    "Symbol",
    "Exchange Symbol",
    "Status",
    "Maker Fee",
    "Taker Fee",
    "Min Price",
    "Max Price",
    "Price Increment",
    "Min Size",
    "Max Size",
    "Size Increment",
    "Min Notional"
  ]

  @spec products :: no_return
  def products do
    Tai.Exchanges.ProductStore.all()
    |> Enum.sort(&(&1.symbol < &2.symbol))
    |> format_rows
    |> render!(@header)
  end

  defp format_rows(products) do
    products
    |> Enum.map(fn product ->
      [
        product.exchange_id,
        product.symbol,
        product.exchange_symbol,
        product.status,
        product.maker_fee && product.maker_fee |> to_percent,
        product.taker_fee && product.taker_fee |> to_percent,
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

  @hundred Decimal.new(100)
  defp to_percent(%Decimal{} = val) do
    "#{val |> Decimal.mult(@hundred) |> Decimal.reduce()}%"
  end

  defp format_col(%Decimal{} = val) do
    val
    |> Decimal.reduce()
    |> Decimal.to_string(:normal)
  end

  defp format_col(val), do: val
end
