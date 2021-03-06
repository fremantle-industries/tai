defmodule Tai.IEx.Commands.FundingRates do
  @moduledoc """
  Display the funding rates for products
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Time",
    "Venue",
    "Symbol",
    "Rate"
  ]

  @spec funding_rates :: no_return
  def funding_rates do
    Tai.Commander.funding_rates()
    |> format_rows
    |> render!(@header)
  end

  defp format_rows(fees) do
    fees
    |> Enum.map(fn f ->
      [
        f.time,
        f.venue,
        f.product_symbol,
        {f.rate, :percent}
      ]
      |> Enum.map(&format_col/1)
    end)
  end

  defp format_col({val, :percent}) do
    percent =
      val
      |> Decimal.normalize()
      |> Decimal.to_string(:normal)

    "#{percent}%"
  end

  defp format_col(val), do: val
end
