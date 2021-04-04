defmodule Tai.Events.OrderUpdateInvalidStatusTest do
  use ExUnit.Case, async: true

  test ".to_data/1 transforms datetime data to a string" do
    {:ok, last_received_at, _} = DateTime.from_iso8601("2014-01-23T23:50:07.123+00:00")
    {:ok, last_venue_timestamp, _} = DateTime.from_iso8601("2020-01-23T23:50:07.123+00:00")

    event =
      struct!(Tai.Events.OrderUpdateInvalidStatus,
        client_id: "my_client_id",
        transition: TransitionA,
        was: :was_status,
        required: [:required_status_a, :required_status_b],
        last_received_at: last_received_at,
        last_venue_timestamp: last_venue_timestamp
      )

    assert %{} = json = TaiEvents.LogEvent.to_data(event)
    assert json.client_id == "my_client_id"
    assert json.transition == TransitionA
    assert json.was == :was_status
    assert json.required == [:required_status_a, :required_status_b]
    assert json.last_received_at == "2014-01-23T23:50:07.123Z"
    assert json.last_venue_timestamp == "2020-01-23T23:50:07.123Z"
  end
end
