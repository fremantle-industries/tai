defmodule Tai.IEx.Commands.Fees do
  @moduledoc """
  Display the list of maker/taker fees for tradable products
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Credential",
    "Symbol",
    "Maker",
    "Taker"
  ]

  @spec fees :: no_return
  def fees do
    Tai.Commander.fees()
    |> format_rows
    |> render!(@header)
  end

  defp format_rows(fees) do
    fees
    |> Enum.map(fn f ->
      [
        f.venue_id,
        f.credential_id,
        f.symbol,
        {f.maker, f.maker_type},
        {f.taker, f.taker_type}
      ]
      |> Enum.map(&format_col/1)
    end)
  end

  defp format_col({val, :percent}) do
    percent =
      val
      |> Decimal.mult(Decimal.new(100))
      |> Decimal.normalize()
      |> Decimal.to_string(:normal)

    "#{percent}%"
  end

  defp format_col({val, _type}) do
    val
    |> Decimal.normalize()
    |> Decimal.to_string(:normal)
  end

  defp format_col(val), do: val
end
