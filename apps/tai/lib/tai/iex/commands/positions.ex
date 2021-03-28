defmodule Tai.IEx.Commands.Positions do
  @moduledoc """
  Display the list of positions and their details
  """

  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Credential",
    "Product",
    "Side",
    "Qty",
    "Entry Price",
    "Leverage",
    "Margin Mode"
  ]

  @spec positions :: no_return
  def positions do
    Tai.Commander.positions()
    |> Enum.sort(&(&1.venue_id < &2.venue_id))
    |> Enum.map(fn position ->
      [
        position.venue_id,
        position.credential_id,
        position.product_symbol,
        position.side,
        position.qty,
        position.entry_price,
        position.leverage,
        position.margin_mode
      ]
    end)
    |> render!(@header)
  end
end
