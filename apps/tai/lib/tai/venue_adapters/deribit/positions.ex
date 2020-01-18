defmodule Tai.VenueAdapters.Deribit.Positions do
  def positions(venue_id, credential_id, credentials) do
    venue_credentials = to_venue_credentials(credentials)

    with {:ok, currencies} <- ExDeribit.MarketData.Currencies.get(),
         {:ok, venue_positions} <- fetch_venue_positions(currencies, venue_credentials) do
      positions =
        venue_positions
        |> Enum.map(&build(&1, venue_id, credential_id))
        |> Enum.filter(& &1)

      {:ok, positions}
    end
  end

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Deribit.Credentials,
    as: :from

  defp fetch_venue_positions(currencies, venue_credentials) do
    currencies
    |> Enum.reduce(
      {:ok, []},
      fn c, {:ok, existing_venue_positions} ->
        with {:ok, currency_venue_positions} <-
               ExDeribit.Accounts.Positions.get(venue_credentials, c.currency) do
          {:ok, existing_venue_positions ++ currency_venue_positions}
        end
      end
    )
  end

  defdelegate to_symbol(instrument_name),
    to: Tai.VenueAdapters.Deribit.Product

  defp build(%ExDeribit.Position{direction: "zero"}, _, _), do: nil

  defp build(venue_position, venue_id, credential_id) do
    product_symbol = venue_position.instrument_name |> to_symbol()

    %Tai.Trading.Position{
      venue_id: venue_id,
      credential_id: credential_id,
      product_symbol: product_symbol,
      side: venue_position |> side(),
      qty: venue_position |> qty(),
      entry_price: venue_position |> avg_price(),
      leverage: venue_position |> leverage(),
      margin_mode: :crossed
    }
  end

  defp side(%ExDeribit.Position{direction: "buy"}), do: :long
  defp side(%ExDeribit.Position{direction: "sell"}), do: :short

  defp qty(%ExDeribit.Position{size: size}) when size > 0, do: Decimal.cast(size)
  defp qty(%ExDeribit.Position{size: size}) when size < 0, do: Decimal.cast(-size)

  defp avg_price(position), do: Decimal.cast(position.average_price)

  defp leverage(position), do: Decimal.new(position.leverage)
end
