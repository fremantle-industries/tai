defmodule Tai.Events.StreamSubscribeOkTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms trade to a string" do
    {:ok, received_at, _} = DateTime.from_iso8601("2014-01-23T23:50:07.123+00:00")

    event =
      struct!(Tai.Events.StreamSubscribeOk, %{
        venue: :my_venue,
        channel_name: "level2",
        received_at: received_at,
        meta: %{
          venue_symbols: ["BTC-USD", "ETH-USD"]
        }
      })

    assert %{} = json = TaiEvents.LogEvent.to_data(event)
    assert json.venue == :my_venue
    assert json.channel_name == "level2"
    assert json.received_at == received_at
    assert json.meta == %{venue_symbols: ["BTC-USD", "ETH-USD"]}
  end
end
