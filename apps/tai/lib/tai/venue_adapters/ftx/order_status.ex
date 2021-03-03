defmodule Tai.VenueAdapters.Ftx.OrderStatus do
  def from_venue("new"), do: :create_accepted
  # TODO: This probably needs to handle partially filled also...
  def from_venue("open"), do: :open
  # TODO: How should closed be properly handled?
  def from_venue("closed"), do: :canceled
end
