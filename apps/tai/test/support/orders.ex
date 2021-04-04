defmodule Support.Orders do
  def setup_orders(start_supervised!) do
    config = Tai.Config.parse()
    start_supervised!.(Tai.TestSupport.Mocks.Server)
    start_supervised!.({TaiEvents, 1})
    start_supervised!.({Tai.Settings, config})
    start_supervised!.({Tai.Trading.OrdersSupervisor, config})
    start_supervised!.(Tai.Venues.VenueStore)
  end
end
