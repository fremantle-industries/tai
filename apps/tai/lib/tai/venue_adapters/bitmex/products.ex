defmodule Tai.VenueAdapters.Bitmex.Products do
  def products(venue_id) do
    with {:ok, instruments, _rate_limit} <-
           ExBitmex.Rest.Instrument.Index.get(%{start: 0, count: 500}) do
      products =
        instruments
        |> Enum.map(&Tai.VenueAdapters.Bitmex.Product.build(&1, venue_id))
        |> Enum.filter(& &1)

      {:ok, products}
    else
      {:error, reason, _} ->
        {:error, reason}
    end
  end

  defdelegate to_symbol(venue_symbol),
    to: Tai.VenueAdapters.Bitmex.Product,
    as: :downcase_and_atom

  defdelegate from_symbol(symbol), to: Tai.VenueAdapters.Bitmex.Product
end
