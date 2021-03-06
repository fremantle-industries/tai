defmodule Tai.IEx.Commands.EstimatedFundingRates do
  @moduledoc """
  Display the estimated funding rates for products
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Next Time",
    "Venue",
    "Symbol",
    "Next Rate"
  ]

  @spec estimated_funding_rates :: no_return
  def estimated_funding_rates do
    Tai.Commander.estimated_funding_rates()
    |> format_rows
    |> render!(@header)
  end

  defp format_rows(fees) do
    fees
    |> Enum.map(fn f ->
      [
        f.next_time,
        f.venue,
        f.product_symbol,
        {f.next_rate, :percent}
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
