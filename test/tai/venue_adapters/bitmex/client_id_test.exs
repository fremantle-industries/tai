defmodule Tai.VenueAdapters.Bitmex.ClientIdTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Bitmex.ClientId

  test ".to_venue is a v4 uuid, base64 encoded with padding and a time in force prefix" do
    assert ClientId.to_venue("9c60858a-b76f-4184-8d1e-df9d247fb197", :gtc) ==
             "gtc-nGCFirdvQYSNHt+dJH+xlw=="
  end

  test ".from_base64 is a hex encoded string of the base64 uuid" do
    assert ClientId.from_base64("nGCFirdvQYSNHt+dJH+xlw==") ==
             "9c60858a-b76f-4184-8d1e-df9d247fb197"
  end
end
