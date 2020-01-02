defmodule Tai.TestSupport.Mocks.Responses.AssetBalances do
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credential :: Tai.Venue.credential()

  @deprecated "Use Tai.TestSupport.Mocks.Responses.Accounts.for_venue_and_credential/3 instead."
  @spec for_venue_and_account(venue_id, credential_id, credential) :: :ok
  def for_venue_and_account(venue_id, credential_id, credential) do
    Tai.TestSupport.Mocks.Responses.Accounts.for_venue_and_credential(
      venue_id,
      credential_id,
      credential
    )
  end

  @deprecated "Use Tai.TestSupport.Mocks.Responses.Accounts.for_venue_and_credential/3 instead."
  @spec for_venue_and_credential(venue_id, credential_id, credential) :: :ok
  def for_venue_and_credential(venue_id, credential_id, credential) do
    Tai.TestSupport.Mocks.Responses.Accounts.for_venue_and_credential(
      venue_id,
      credential_id,
      credential
    )
  end
end
