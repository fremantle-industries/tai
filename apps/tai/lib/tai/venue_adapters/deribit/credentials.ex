defmodule Tai.VenueAdapters.Deribit.Credentials do
  def from(credentials), do: struct!(ExDeribit.Credentials, credentials)
end
