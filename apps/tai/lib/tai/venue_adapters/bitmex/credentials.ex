defmodule Tai.VenueAdapters.Bitmex.Credentials do
  def from(%{api_key: _, api_secret: _} = attrs) do
    struct!(ExBitmex.Credentials, attrs)
  end
end
