defmodule Tai.VenueAdapters.OkEx.ClientIdTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.OkEx.ClientId

  test ".to_venue returns the v4 uuid base32 encoded without padding" do
    assert ClientId.to_venue("9c60858a-b76f-4184-8d1e-df9d247fb197") ==
             "TRQILCVXN5AYJDI636OSI75RS4"
  end

  test ".from_base32 is a hex encoded string of the base32 encoded v4 uuid string without padding" do
    assert ClientId.from_base32("TRQILCVXN5AYJDI636OSI75RS4") ==
             "9c60858a-b76f-4184-8d1e-df9d247fb197"
  end
end
