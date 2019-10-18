defmodule Tai.Trading.Position do
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type t :: %Tai.Trading.Position{
          venue_id: atom,
          account_id: atom,
          product_symbol: product_symbol,
          open: boolean,
          avg_entry_price: Decimal.t() | nil,
          qty: Decimal.t(),
          init_margin: Decimal.t(),
          init_margin_req: Decimal.t(),
          maint_margin: Decimal.t(),
          maint_margin_req: Decimal.t(),
          realised_pnl: Decimal.t(),
          unrealised_pnl: Decimal.t()
        }

  @enforce_keys ~w(
    venue_id
    account_id
    product_symbol
    open
    qty
    init_margin
    init_margin_req
    maint_margin
    maint_margin_req
    realised_pnl
    unrealised_pnl
  )a
  defstruct ~w(
    venue_id
    account_id
    product_symbol
    open
    avg_entry_price
    qty
    init_margin
    init_margin_req
    maint_margin
    maint_margin_req
    realised_pnl
    unrealised_pnl
  )a
end
