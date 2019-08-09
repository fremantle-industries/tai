defmodule Tai.TestSupport.Mocks.Responses.MakerTakerFees do
  @type venue_id :: Tai.Venues.Adapter.venue_id()
  @type account_id :: Tai.Venues.Adapter.account_id()
  @type fee :: {maker :: Decimal.t(), taker :: Decimal.t()}

  @spec for_venue_and_account(venue_id, account_id, fee) :: :ok
  def for_venue_and_account(venue_id, account_id, {_, _} = maker_taker_fees) do
    {:maker_taker_fees, venue_id, account_id}
    |> Tai.TestSupport.Mocks.Server.insert(maker_taker_fees)
  end

  @deprecated "Use Tai.TestSupport.Mocks.Responses.MakerTakerFees.for_venue_and_account/3 instead."
  def for_exchange_and_account(venue_id, account_id, maker_taker_fees) do
    for_venue_and_account(venue_id, account_id, maker_taker_fees)
  end
end
