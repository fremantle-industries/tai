defmodule Tai.ExchangeAdapters.Mock.Account do
  use Tai.Exchanges.Account

  defdelegate create_order(order, credentials), to: Tai.VenueAdapters.Mock

  defdelegate amend_order(order, attrs, credentials), to: Tai.VenueAdapters.Mock

  defdelegate cancel_order(venue_order_id, credentials), to: Tai.VenueAdapters.Mock

  def order_status(_venue_order_id, _credentials) do
    {:error, :not_implemented}
  end
end
