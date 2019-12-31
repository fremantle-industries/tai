defmodule Tai.Commands.Fees do
  @moduledoc """
  Display the list of maker/taker fees for tradable products
  """

  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Credential",
    "Symbol",
    "Maker",
    "Taker"
  ]

  @spec fees :: no_return
  def fees do
    Tai.Venues.FeeStore.all()
    |> Enum.sort(&(&1.venue_id < &2.venue_id))
    |> format_rows
    |> render!(@header)
  end

  defp format_rows(fees) do
    fees
    |> Enum.map(fn fee_info ->
      [
        fee_info.venue_id,
        fee_info.credential_id,
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
end
