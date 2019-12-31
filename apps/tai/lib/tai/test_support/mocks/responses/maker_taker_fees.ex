defmodule Tai.TestSupport.Mocks.Responses.MakerTakerFees do
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type fee :: {maker :: Decimal.t(), taker :: Decimal.t()}

  @spec for_venue_and_account(venue_id, credential_id, fee) :: :ok
  def for_venue_and_account(venue_id, credential_id, maker_taker_fees) do
    for_venue_and_credential(venue_id, credential_id, maker_taker_fees)
  end

  @spec for_venue_and_credential(venue_id, credential_id, fee) :: :ok
  def for_venue_and_credential(venue_id, credential_id, {_, _} = maker_taker_fees) do
    {:maker_taker_fees, venue_id, credential_id}
    |> Tai.TestSupport.Mocks.Server.insert(maker_taker_fees)
  end
end
