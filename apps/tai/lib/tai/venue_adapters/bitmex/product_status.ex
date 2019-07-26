defmodule Tai.VenueAdapters.Bitmex.ProductStatus do
  @spec normalize(bitmex_state :: String.t()) :: :trading | :settled | :unlisted
  def normalize("Open"), do: :trading
  def normalize("Settled"), do: :settled
  def normalize("Unlisted"), do: :unlisted
end
