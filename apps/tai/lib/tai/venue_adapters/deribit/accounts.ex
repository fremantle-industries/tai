defmodule Tai.VenueAdapters.Deribit.Accounts do
  def accounts(venue_id, credential_id, credentials) do
    venue_credentials = credentials |> to_venue_credentials()

    with {:ok, currencies} <- ExDeribit.MarketData.Currencies.get(),
         {:ok, summaries} <- fetch_summaries(currencies, venue_credentials) do
      accounts = summaries |> Enum.map(&build(&1, venue_id, credential_id))

      {:ok, accounts}
    end
  end

  @zero Decimal.new(0)

  def build(account_summary, venue_id, credential_id) do
    equity = account_summary.equity |> Decimal.cast()
    asset = account_summary.currency |> String.downcase() |> String.to_atom()

    %Tai.Venues.Account{
      venue_id: venue_id,
      credential_id: credential_id,
      asset: asset,
      type: "default",
      equity: equity,
      free: @zero,
      locked: equity
    }
  end

  defdelegate to_venue_credentials(credentials),
    to: Tai.VenueAdapters.Deribit.Credentials,
    as: :from

  defp fetch_summaries(currencies, venue_credentials) do
    currencies
    |> Enum.reduce(
      {:ok, []},
      fn c, {:ok, existing_summaries} ->
        with {:ok, currency_summary} <-
               ExDeribit.Accounts.Summary.get(venue_credentials, c.currency) do
          {:ok, existing_summaries ++ [currency_summary]}
        end
      end
    )
  end
end
