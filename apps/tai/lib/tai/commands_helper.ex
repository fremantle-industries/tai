defmodule Tai.CommandsHelper do
  @moduledoc """
  Commands to control `tai` in IEx
  """

  @deprecated "Use Tai.IEx.help/0 instead."
  def help do
    Tai.IEx.help()
  end

  @deprecated "Use Tai.IEx.accounts/0 instead."
  def accounts do
    Tai.IEx.accounts()
  end

  @deprecated "Use Tai.IEx.products/0 instead."
  def products do
    Tai.IEx.products()
  end

  @deprecated "Use Tai.IEx.fees/0 instead."
  def fees do
    Tai.IEx.fees()
  end

  @deprecated "Use Tai.IEx.markets/0 instead."
  def markets do
    Tai.IEx.markets()
  end

  @deprecated "Use Tai.IEx.positions/0 instead."
  def positions do
    Tai.IEx.positions()
  end

  @deprecated "Use Tai.IEx.orders/0 instead."
  def orders do
    Tai.IEx.orders()
  end

  @deprecated "Use Tai.IEx.venues/1 instead."
  def venues(args \\ []) do
    Tai.IEx.venues(args)
  end

  @deprecated "Use Tai.IEx.start_venue/2 instead."
  def start_venue(venue, store_id \\ Tai.Venues.VenueStore.default_store_id()) do
    Tai.IEx.start_venue(venue, store_id)
  end

  @deprecated "Use Tai.IEx.stop_venue/2 instead."
  def stop_venue(venue, store_id \\ Tai.Venues.VenueStore.default_store_id()) do
    Tai.IEx.stop_venue(venue, store_id)
  end

  @deprecated "Use Tai.IEx.advisors/1 instead."
  def advisors(args \\ []) do
    Tai.IEx.advisors(args)
  end

  @deprecated "Use Tai.IEx.start_advisors/1 instead."
  def start_advisors(args \\ []) do
    Tai.IEx.start_advisors(args)
  end

  @deprecated "Use Tai.IEx.stop_advisors/1 instead."
  def stop_advisors(args \\ []) do
    Tai.IEx.stop_advisors(args)
  end

  @deprecated "Use Tai.IEx.settings/0 instead."
  def settings do
    Tai.IEx.settings()
  end

  @deprecated "Use Tai.IEx.enable_send_orders/0 instead."
  def enable_send_orders do
    Tai.IEx.enable_send_orders()
  end

  @deprecated "Use Tai.IEx.disable_send_orders/0 instead."
  def disable_send_orders do
    Tai.IEx.disable_send_orders()
  end
end
