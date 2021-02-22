defmodule Tai.VenueAdapters.Ftx.Products do
  alias ExFtx.Markets

  def products(venue_id) do
    with {:ok, markets} <- Markets.List.get() do
      products =
        markets |> Enum.map(&Tai.VenueAdapters.Ftx.Product.build(&1, venue_id))

      {:ok, products}
    end
  end

  defdelegate to_symbol(market_name), to: Tai.VenueAdapters.Ftx.Product
end
