defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdatePositionTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  @venue :venue_a
  @credential_id :main
  @credential {@credential_id, %{}}

  setup do
    start_supervised!({ProcessAuth, [venue: @venue, credential: @credential]})
    :ok
  end

  test "updates equity & locked on the existing position" do
    {:ok, _} =
      Tai.Trading.Position
      |> struct(
        venue_id: @venue,
        credential_id: @credential_id,
        product_symbol: :xbtusd,
        qty: Decimal.new(1)
      )
      |> Tai.Trading.PositionStore.put()

    Tai.SystemBus.subscribe(:position_store)

    venue_msg = %{
      "table" => "position",
      "action" => "update",
      "data" => [
        %{
          "account" => 158_677,
          "currency" => "XBt",
          "currentQty" => 2,
          "currentTimestamp" => "2020-03-13T23:30:05.364Z",
          "lastPrice" => 5656.81,
          "liquidationPrice" => 1,
          "maintMargin" => 138,
          "markPrice" => 5656.81,
          "posComm" => 14,
          "posMaint" => 123,
          "posMargin" => 5473,
          "symbol" => "XBTUSD",
          "timestamp" => "2020-03-13T23:30:05.364Z"
        }
      ]
    }

    @venue
    |> ProcessAuth.to_name()
    |> GenServer.cast({venue_msg, Timex.now()})

    assert_receive {:position_store, :after_put, updated_position}
    assert updated_position.qty == Decimal.new(2)
  end
end
