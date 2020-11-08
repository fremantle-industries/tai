defmodule Tai.IEx.Commands.Products do
  @moduledoc """
  Display the list of products for each venue
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Symbol",
    "Venue Symbol",
    "Status",
    "Type",
    "Maker Fee",
    "Taker Fee"
  ]

  @spec products :: no_return
  def products do
    Tai.Commander.products()
    |> format_rows
    |> render!(@header)
  end

  defp format_rows(products) do
    products
    |> Enum.map(fn product ->
      [
        product.venue_id,
        product.symbol,
        product.venue_symbol,
        product.status,
        product.type,
        product.maker_fee && product.maker_fee |> to_percent,
        product.taker_fee && product.taker_fee |> to_percent
      ]
      |> Enum.map(&format_col/1)
    end)
  end

  @hundred Decimal.new(100)
  defp to_percent(%Decimal{} = val) do
    "#{val |> Decimal.mult(@hundred) |> Decimal.normalize()}%"
  end

  defp format_col(%Decimal{} = val) do
    val
    |> Decimal.normalize()
    |> Decimal.to_string(:normal)
  end

  defp format_col(val), do: val
end
