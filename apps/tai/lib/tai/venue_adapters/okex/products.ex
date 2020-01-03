defmodule Tai.VenueAdapters.OkEx.Products do
  alias ExOkex.{Futures, Swap, Spot}

  def products(venue_id) do
    with {:ok, future_instruments} <- Futures.Public.instruments(),
         {:ok, swap_instruments} <- Swap.Public.instruments(),
         {:ok, spot_instruments} <- Spot.Public.instruments() do
      future_products =
        future_instruments |> Enum.map(&Tai.VenueAdapters.OkEx.Product.build(&1, venue_id))

      swap_products =
        swap_instruments |> Enum.map(&Tai.VenueAdapters.OkEx.Product.build(&1, venue_id))

      spot_products =
        spot_instruments |> Enum.map(&Tai.VenueAdapters.OkEx.Product.build(&1, venue_id))

      products = future_products ++ swap_products ++ spot_products

      {:ok, products}
    end
  end

  defdelegate to_symbol(instrument_id), to: Tai.VenueAdapters.OkEx.Product
  defdelegate from_symbol(symbol), to: Tai.VenueAdapters.OkEx.Product
end
