defmodule Tai.VenueAdapters.Deribit.Products do
  def products(venue_id) do
    with {:ok, currencies} <- ExDeribit.MarketData.Currencies.get(),
         {:ok, instruments} <- fetch_instruments(currencies) do
      products =
        instruments
        |> Enum.map(&Tai.VenueAdapters.Deribit.Product.build(&1, venue_id))

      {:ok, products}
    end
  end

  defp fetch_instruments(currencies) do
    currencies
    |> Enum.reduce(
      {:ok, []},
      fn c, {:ok, existing_instruments} ->
        with {:ok, currency_instruments} <-
               ExDeribit.MarketData.Instruments.get(c.currency) do
          {:ok, existing_instruments ++ currency_instruments}
        end
      end
    )
  end
end
