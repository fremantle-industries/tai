defmodule Tai.AdvisorResponders.Responder do
  @doc """
  Receives orderbook changes and
  """
  @type state :: Tai.Advisor.State.t()
  @type response :: map
  @type action :: :order_book_changes | :order_book_snapshot
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type product_symbol :: Tai.Venues.Product.symbol()

  @callback respond({response, state}, {action, venue_id, product_symbol, map}) ::
              {:ok, {response, state}}
end
