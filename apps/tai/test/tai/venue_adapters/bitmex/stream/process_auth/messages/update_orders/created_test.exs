defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.CreatedTest do
  use ExUnit.Case, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @venue_client_id "gtc-TCRG7aPSQsmj1Z8jXfbovg=="
  @received_at Timex.now()
  @timestamp "2019-09-07T06:00:04.808Z"
  @state struct(ProcessAuth.State)

  test ".process/3 returns :ok" do
    msg =
      struct(ProcessAuth.Messages.UpdateOrders.Created,
        cl_ord_id: @venue_client_id,
        timestamp: @timestamp
      )

    assert ProcessAuth.Message.process(msg, @received_at, @state) == :ok
  end
end
