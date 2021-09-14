defmodule Examples.LogTrade.Advisor do
  @moduledoc """
  Log streaming trades for a product
  """

  use Tai.Advisor

  @impl true
  def handle_trade(trade, state) do
    %Examples.LogTrade.Events.Trade{
      id: trade.id,
      venue: trade.venue,
      product_symbol: trade.product_symbol,
      price: trade.price,
      qty: trade.qty,
      side: trade.side,
      liquidation: trade.liquidation,
      received_at: trade.received_at,
      venue_timestamp: trade.venue_timestamp
    }
    |> TaiEvents.info()

    {:ok, state.store}
  end
end
