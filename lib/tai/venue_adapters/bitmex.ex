defmodule Tai.VenueAdapters.Bitmex do
  use Tai.Exchanges.Adapter

  def stream_supervisor, do: Tai.VenueAdapters.Bitmex.StreamSupervisor

  def order_book_feed, do: Tai.VenueAdapters.NullOrderBookFeed

  defdelegate products(venue_id), to: Tai.VenueAdapters.Bitmex.Products

  def asset_balances(_, _, _), do: {:ok, []}

  def maker_taker_fees(_, _, _), do: {:ok, nil}
end
