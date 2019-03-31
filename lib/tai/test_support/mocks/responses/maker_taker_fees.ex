defmodule Tai.TestSupport.Mocks.Responses.MakerTakerFees do
  @spec for_exchange_and_account(
          venue_id :: Tai.Venues.Adapter.venue_id(),
          account_id :: Tai.Venues.Adapter.account_id(),
          {maker :: Decimal.t(), taker :: Decimal.t()}
        ) :: :ok
  def for_exchange_and_account(venue_id, account_id, {_, _} = maker_taker_fees) do
    key = Tai.VenueAdapters.Mock.maker_taker_fees_response_key({venue_id, account_id})
    :ok = Tai.TestSupport.Mocks.Server.insert(key, maker_taker_fees)

    :ok
  end
end
