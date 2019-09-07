defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.VenueMessage do
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  defmodule DefaultProvider do
    @empty []

    def update_orders(data), do: ProcessAuth.VenueMessages.UpdateOrders.extract(data)
    def empty, do: @empty
    def unhandled(msg), do: [%ProcessAuth.Messages.Unhandled{msg: msg}]
  end

  @type venue_message :: map
  @type provider :: module

  @spec extract(venue_message, provider) :: [struct]
  def extract(msg, provider \\ DefaultProvider)

  def extract(%{"table" => "order", "action" => "update", "data" => data}, provider) do
    provider.update_orders(data)
  end

  def extract(%{"table" => "order", "action" => "insert"}, provider), do: provider.empty
  def extract(%{"table" => "transact"}, provider), do: provider.empty
  def extract(%{"table" => "execution"}, provider), do: provider.empty
  def extract(%{"table" => "wallet"}, provider), do: provider.empty
  def extract(%{"table" => "margin"}, provider), do: provider.empty
  def extract(%{"table" => "position"}, provider), do: provider.empty
  def extract(msg, provider), do: provider.unhandled(msg)
end
