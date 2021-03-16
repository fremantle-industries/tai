defmodule Tai.VenueAdapters.Bitmex.Products do
  def products(venue_id) do
    get_paginated_products([], venue_id, 0)
  end

  defdelegate to_symbol(venue_symbol),
    to: Tai.VenueAdapters.Bitmex.Product,
    as: :downcase_and_atom

  @count 500
  defp get_paginated_products(acc, venue_id, start) do
    case ExBitmex.Rest.Instrument.Index.get(%{start: start, count: @count}) do
      {:ok, [], _rate_limit} ->
        {:ok, acc}

      {:ok, instruments, _rate_limit} ->
        products =
          instruments
          |> Enum.map(&Tai.VenueAdapters.Bitmex.Product.build(&1, venue_id))
          |> Enum.filter(& &1)

        get_paginated_products(acc ++ products, venue_id, start + @count)

      {:error, reason, _} ->
        {:error, reason}
    end
  end
end
