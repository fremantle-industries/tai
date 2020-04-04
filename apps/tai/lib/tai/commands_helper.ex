defmodule Tai.CommandsHelper do
  @moduledoc """
  Commands to control `tai` in IEx
  """

  alias Tai.IEx.Commands

  @type venue :: Tai.Venue.id()
  @type venue_store_id :: Tai.Venues.VenueStore.store_id()

  @deprecated "Use Tai.IEx.help/0 instead."
  @spec help :: no_return
  def help do
    Tai.IEx.help()
  end

  @deprecated "Use Tai.IEx.accounts/0 instead."
  @spec accounts :: no_return
  def accounts do
    Tai.IEx.accounts()
  end

  @deprecated "Use Tai.IEx.products/0 instead."
  @spec products :: no_return
  def products do
    Tai.IEx.products()
  end

  @deprecated "Use Tai.IEx.fees/0 instead."
  @spec fees :: no_return
  def fees do
    Tai.IEx.fees()
  end

  @deprecated "Use Tai.IEx.markets/0 instead."
  @spec markets :: no_return
  def markets do
    Tai.IEx.markets()
  end

  @deprecated "Use Tai.IEx.positions/0 instead."
  @spec positions :: no_return
  def positions do
    Tai.IEx.positions()
  end

  @deprecated "Use Tai.IEx.orders/0 instead."
  @spec orders :: no_return
  def orders do
    Tai.IEx.orders()
  end

  @deprecated "Use Tai.IEx.venues/1 instead."
  @spec venues() :: no_return
  @spec venues(list) :: no_return
  def venues(args \\ []) do
    Tai.IEx.venues(args)
  end

  @deprecated "Use Tai.IEx.start_venue/2 instead."
  @spec start_venue(venue) :: no_return
  @spec start_venue(venue, Commands.StartVenue.options()) :: no_return
  def start_venue(venue, options \\ []) do
    Tai.IEx.start_venue(venue, options)
  end

  @deprecated "Use Tai.IEx.stop_venue/2 instead."
  @spec stop_venue(venue) :: no_return
  @spec stop_venue(venue, Commands.StopVenue.options()) :: no_return
  def stop_venue(venue, options \\ []) do
    Tai.IEx.stop_venue(venue, options)
  end

  @deprecated "Use Tai.IEx.advisors/1 instead."
  @spec advisors() :: no_return
  @spec advisors(list) :: no_return
  def advisors(args \\ []) do
    Tai.IEx.advisors(args)
  end

  @deprecated "Use Tai.IEx.start_advisors/1 instead."
  @spec start_advisors() :: no_return
  @spec start_advisors(list) :: no_return
  def start_advisors(args \\ []) do
    Tai.IEx.start_advisors(args)
  end

  @deprecated "Use Tai.IEx.stop_advisors/1 instead."
  @spec stop_advisors() :: no_return
  @spec stop_advisors(list) :: no_return
  def stop_advisors(args \\ []) do
    Tai.IEx.stop_advisors(args)
  end

  @deprecated "Use Tai.IEx.settings/0 instead."
  @spec settings :: no_return
  def settings do
    Tai.IEx.settings()
  end

  @deprecated "Use Tai.IEx.enable_send_orders/0 instead."
  @spec enable_send_orders :: no_return
  def enable_send_orders do
    Tai.IEx.enable_send_orders()
  end

  @deprecated "Use Tai.IEx.disable_send_orders/0 instead."
  @spec disable_send_orders :: no_return
  def disable_send_orders do
    Tai.IEx.disable_send_orders()
  end
end
