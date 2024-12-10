defmodule Tai.VenueAdapters.Bitmex.ProductType do
  @type type :: Tai.Venues.Product.type()

  @doc """
  Maps Bitmex product types to Tai product types.

  https://www.bitmex.com/api/explorer/#!/Instrument/Instrument_get

  Perpetual Contracts - FFWCSX
  Perpetual Contracts (FX underliers) - FFWCSF
  Spot - IFXXXP
  Futures - FFCCSX
  BitMEX Basket Index - MRBXXX
  BitMEX Crypto Index - MRCXXX
  BitMEX FX Index - MRFXXX
  BitMEX Lending/Premium Index - MRRXXX
  BitMEX Volatility Index - MRIXXX

  ## Examples

      iex> Tai.VenueAdapters.Bitmex.ProductType.normalize("FFWCSX")
      :swap

  """

  @spec normalize(bitmex_product_type :: String.t()) :: type
  def normalize("FFWCS" <> _), do: :swap # FFWCSX, FFWCSF
  def normalize("FFCCS" <> _), do: :future # FFCCSX
  def normalize("IF" <> _), do: :spot # IFXXXP
  def normalize(_), do: :future
end
