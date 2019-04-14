defmodule Tai.VenueAdapters.OkEx.Credentials do
  def from(credentials), do: ExOkex.Config |> struct!(credentials)
end
