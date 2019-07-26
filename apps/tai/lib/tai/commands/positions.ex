defmodule Tai.Commands.Positions do
  @moduledoc """
  Display the list of positions and their details
  """

  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Venue",
    "Account",
    "Product",
    "Open",
    "Avg Entry Price",
    "Qty",
    "Init Margin",
    "Init Margin Req",
    "Maint Margin",
    "Maint Margin Req",
    "Realised Pnl",
    "Unrealised Pnl"
  ]

  @spec positions :: no_return
  def positions do
    Tai.Trading.PositionStore.all()
    |> Enum.sort(&(&1.venue_id < &2.venue_id))
    |> Enum.map(fn position ->
      [
        position.venue_id,
        position.account_id,
        position.product_symbol,
        position.open,
        position.avg_entry_price,
        position.qty,
        position.init_margin,
        position.init_margin_req,
        position.maint_margin,
        position.maint_margin_req,
        position.realised_pnl,
        position.unrealised_pnl
      ]
    end)
    |> render!(@header)
  end
end
