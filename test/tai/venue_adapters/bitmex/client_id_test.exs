defmodule Tai.VenueAdapters.Bitmex.ClientIdTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Bitmex.ClientId

  describe ".to_venue" do
    test "returns custom client id within 36 char limit, with a passive order update filter" do
      assert ClientId.to_venue("9c60858a-b76f-4184-8d1e-df9d247fb197", :gtc) ==
               "gtc-nGCFirdvQYSNHt+dJH+xlw=="
    end
  end
end
