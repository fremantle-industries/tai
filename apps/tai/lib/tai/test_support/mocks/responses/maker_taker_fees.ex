defmodule Tai.TestSupport.Mocks.Responses.MakerTakerFees do
  @spec for_exchange_and_account(
          venue_id :: Tai.Venues.Adapter.venue_id(),
          account_id :: Tai.Venues.Adapter.account_id(),
          {maker :: Decimal.t(), taker :: Decimal.t()}
        ) :: :ok
  def for_exchange_and_account(venue_id, account_id, {_, _} = maker_taker_fees) do
    {:maker_taker_fees, venue_id, account_id}
    |> Tai.TestSupport.Mocks.Server.insert(maker_taker_fees)
  end
end
