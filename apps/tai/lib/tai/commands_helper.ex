defmodule Tai.CommandsHelper do
  @moduledoc """
  Commands for using `tai` in IEx
  """

  @type venue :: Tai.Venue.id()
  @type venue_store_id :: Tai.Venues.VenueStore.store_id()

  @spec help :: no_return
  defdelegate help, to: Tai.Commands.Help

  @spec accounts :: no_return
  defdelegate accounts, to: Tai.Commands.Accounts

  @spec products :: no_return
  defdelegate products, to: Tai.Commands.Products

  @spec fees :: no_return
  defdelegate fees, to: Tai.Commands.Fees

  @spec markets :: no_return
  defdelegate markets, to: Tai.Commands.Markets

  @spec positions :: no_return
  defdelegate positions, to: Tai.Commands.Positions

  @spec orders :: no_return
  defdelegate orders, to: Tai.Commands.Orders

  @spec venues() :: no_return
  @spec venues(list) :: no_return
  defdelegate venues(args \\ []), to: Tai.Commands.Venues, as: :list

  @spec start_venue(venue) :: no_return
  @spec start_venue(venue, venue_store_id) :: no_return
  defdelegate start_venue(venue, store_id \\ Tai.Venues.VenueStore.default_store_id()),
    to: Tai.Commands.StartVenue,
    as: :start

  @spec stop_venue(venue) :: no_return
  @spec stop_venue(venue, venue_store_id) :: no_return
  defdelegate stop_venue(venue, store_id \\ Tai.Venues.VenueStore.default_store_id()),
    to: Tai.Commands.StopVenue,
    as: :stop

  @spec advisors() :: no_return
  @spec advisors(list) :: no_return
  defdelegate advisors(args \\ []), to: Tai.Commands.Advisors, as: :list

  @spec start_advisors() :: no_return
  @spec start_advisors(list) :: no_return
  defdelegate start_advisors(args \\ []), to: Tai.Commands.Advisors, as: :start

  @spec stop_advisors() :: no_return
  @spec stop_advisors(list) :: no_return
  defdelegate stop_advisors(args \\ []), to: Tai.Commands.Advisors, as: :stop

  @spec settings :: no_return
  defdelegate settings, to: Tai.Commands.Settings

  @spec enable_send_orders :: no_return
  defdelegate enable_send_orders, to: Tai.Commands.SendOrders, as: :enable

  @spec disable_send_orders :: no_return
  defdelegate disable_send_orders, to: Tai.Commands.SendOrders, as: :disable
end
