defmodule Tai.VenueAdapters.Bybit.Products do
  alias ExBybit.Derivatives
  alias Tai.VenueAdapters.Bybit.Product

  def products(venue_id) do
    with {:ok, derivative_symbols} <- Derivatives.Market.Symbols.List.get() do
      products = derivative_symbols |> Enum.map(&Product.build(&1, venue_id))
      {:ok, products}
    end
  end
end
