defmodule Tai.VenueAdapters.Huobi.Products do
  alias ExHuobi.{Futures, Swaps}

  def products(venue_id) do
    with {:ok, future_instruments} <- Futures.Contracts.get(),
         {:ok, swap_instruments} <- Swaps.Contracts.get() do
      future_products =
        future_instruments |> Enum.map(&Tai.VenueAdapters.Huobi.Product.build(&1, venue_id))

      swap_products =
        swap_instruments |> Enum.map(&Tai.VenueAdapters.Huobi.Product.build(&1, venue_id))

      products = future_products ++ swap_products

      {:ok, products}
    end
  end

  defdelegate to_symbol(instrument_id), to: Tai.VenueAdapters.Huobi.Product
end
