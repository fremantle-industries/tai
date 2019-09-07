defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.VenueMessages.UpdateOrdersTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  test ".extract/1 can parse canceled" do
    data = [%{"ordStatus" => "Canceled"}]
    assert [msg | []] = ProcessAuth.VenueMessages.UpdateOrders.extract(data)
    assert %ProcessAuth.Messages.UpdateOrders.Canceled{} = msg
  end

  test ".extract/1 can parse filled" do
    data = [%{"ordStatus" => "Filled"}]
    assert [msg | []] = ProcessAuth.VenueMessages.UpdateOrders.extract(data)
    assert %ProcessAuth.Messages.UpdateOrders.Filled{} = msg
  end

  test ".extract/1 can parse to partially filled" do
    data = [%{"ordStatus" => "PartiallyFilled"}]
    assert [msg | []] = ProcessAuth.VenueMessages.UpdateOrders.extract(data)
    assert %ProcessAuth.Messages.UpdateOrders.ToPartiallyFilled{} = msg
  end

  test ".extract/1 can parse created" do
    data = [%{"orderID" => "abc123", "workingIndicator" => true}]
    assert [msg | []] = ProcessAuth.VenueMessages.UpdateOrders.extract(data)
    assert %ProcessAuth.Messages.UpdateOrders.Created{} = msg
  end

  test ".extract/1 returns unhandled for other messages" do
    venue_msg = %{"iamunhandled" => true}
    assert [msg | []] = ProcessAuth.VenueMessages.UpdateOrders.extract([venue_msg])
    assert %ProcessAuth.Messages.UpdateOrders.Unhandled{} = msg
    assert msg.data == venue_msg
  end
end
