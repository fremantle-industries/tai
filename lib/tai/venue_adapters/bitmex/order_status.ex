defmodule Tai.VenueAdapters.Bitmex.OrderStatus do
  @type order :: Tai.Trading.Order.t()
  @type order_status :: Tai.Trading.Order.status()
  @type venue_status :: String.t()

  @spec from_venue_status(venue_status, order | :ignore) :: order_status
  def from_venue_status(venue_status, order)

  def from_venue_status("New", _), do: :open
  def from_venue_status("PartiallyFilled", _), do: :open
  def from_venue_status("Filled", _), do: :filled
  # https://www.bitmex.com/app/apiChangelog#Jul-5-2016
  def from_venue_status("Canceled", %Tai.Trading.Order{time_in_force: :gtc, post_only: true}),
    do: :rejected

  def from_venue_status("Canceled", %Tai.Trading.Order{time_in_force: :ioc}), do: :expired
  def from_venue_status("Canceled", %Tai.Trading.Order{time_in_force: :fok}), do: :expired
  def from_venue_status("Canceled", _), do: :canceled
  # TODO: Unhandled Bitmex order status
  # defp from_venue_status("PendingNew"), do: :pending
  # defp from_venue_status("DoneForDay"), do: :open
  # defp from_venue_status("Stopped"), do: :open
  # defp from_venue_status("PendingCancel"), do: :pending_cancel
  # defp from_venue_status("Expired"), do: :expired
end
