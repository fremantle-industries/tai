defmodule Tai.IEx do
  @moduledoc """
  Commands to control `tai` in IEx
  """

  alias Tai.IEx.Commands

  @type venue :: Tai.Venue.id()
  @type venue_store_id :: Tai.Venues.VenueStore.store_id()
  @type order_client_id :: Tai.NewOrders.Order.client_id()

  @spec help :: no_return
  defdelegate help, to: Commands.Help

  @spec accounts :: no_return
  defdelegate accounts, to: Commands.Accounts

  @spec products :: no_return
  defdelegate products, to: Commands.Products

  @spec fees :: no_return
  defdelegate fees, to: Commands.Fees

  @spec markets :: no_return
  defdelegate markets, to: Commands.Markets

  @spec positions :: no_return
  defdelegate positions, to: Commands.Positions

  @spec new_orders :: no_return
  defdelegate new_orders, to: Commands.NewOrders

  @spec new_order(order_client_id) :: no_return
  defdelegate new_order(client_id), to: Commands.NewOrder

  @spec order_transitions(order_client_id) :: no_return
  defdelegate order_transitions(client_id), to: Commands.OrderTransitions

  @spec failed_order_transitions(order_client_id) :: no_return
  defdelegate failed_order_transitions(client_id), to: Commands.FailedOrderTransitions

  @spec venues() :: no_return
  @spec venues(Commands.Venues.options()) :: no_return
  defdelegate venues(options \\ []), to: Commands.Venues, as: :list

  @spec start_venue(venue) :: no_return
  @spec start_venue(venue, Commands.StartVenue.options()) :: no_return
  defdelegate start_venue(venue, options \\ []),
    to: Commands.StartVenue,
    as: :start

  @spec stop_venue(venue) :: no_return
  @spec stop_venue(venue, Commands.StopVenue.options()) :: no_return
  defdelegate stop_venue(venue, options \\ []),
    to: Commands.StopVenue,
    as: :stop

  @spec advisors() :: no_return
  @spec advisors(Commands.Advisors.options()) :: no_return
  defdelegate advisors(options \\ []), to: Commands.Advisors, as: :list

  @spec start_advisors() :: no_return
  @spec start_advisors(Commands.StartAdvisors.options()) :: no_return
  defdelegate start_advisors(options \\ []), to: Commands.StartAdvisors, as: :start

  @spec stop_advisors() :: no_return
  @spec stop_advisors(Commands.StopAdvisors.options()) :: no_return
  defdelegate stop_advisors(options \\ []), to: Commands.StopAdvisors, as: :stop

  @spec settings :: no_return
  defdelegate settings, to: Commands.Settings

  @spec enable_send_orders :: no_return
  defdelegate enable_send_orders, to: Commands.EnableSendOrders, as: :enable

  @spec disable_send_orders :: no_return
  defdelegate disable_send_orders, to: Commands.DisableSendOrders, as: :disable
end
