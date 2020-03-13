defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.VenueMessageTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  test ".extract/2 returns a list of order update messages" do
    messages =
      ProcessAuth.VenueMessage.extract(%{
        "table" => "order",
        "action" => "update",
        "data" => [%{"ordStatus" => "Canceled"}, %{"ordStatus" => "Canceled"}]
      })

    assert Enum.count(messages) == 2
    assert %ProcessAuth.Messages.UpdateOrders.Canceled{} = Enum.at(messages, 0)
    assert %ProcessAuth.Messages.UpdateOrders.Canceled{} = Enum.at(messages, 1)
  end

  test ".extract/2 returns a list of account update messages" do
    messages =
      ProcessAuth.VenueMessage.extract(%{
        "table" => "margin",
        "action" => "update",
        "data" => [%{}, %{}]
      })

    assert Enum.count(messages) == 2
    assert %ProcessAuth.Messages.UpdateAccount{} = Enum.at(messages, 0)
    assert %ProcessAuth.Messages.UpdateAccount{} = Enum.at(messages, 1)
  end

  test ".extract/2 returns a list of position update messages" do
    messages =
      ProcessAuth.VenueMessage.extract(%{
        "table" => "position",
        "action" => "update",
        "data" => [%{}, %{}]
      })

    assert Enum.count(messages) == 2
    assert %ProcessAuth.Messages.UpdatePosition{} = Enum.at(messages, 0)
    assert %ProcessAuth.Messages.UpdatePosition{} = Enum.at(messages, 1)
  end

  test ".extract/2 returns an empty list for insert order" do
    assert ProcessAuth.VenueMessage.extract(%{
             "table" => "order",
             "action" => "insert",
             "data" => []
           }) == []
  end

  test ".extract/2 returns an empty list for partial margin" do
    assert ProcessAuth.VenueMessage.extract(%{
             "table" => "margin",
             "action" => "partial",
             "data" => []
           }) == []
  end

  test ".extract/2 returns an empty list for partial position" do
    assert ProcessAuth.VenueMessage.extract(%{
             "table" => "position",
             "action" => "partial",
             "data" => []
           }) == []
  end

  test ".extract/2 returns an empty list for noop tables" do
    assert ProcessAuth.VenueMessage.extract(%{"table" => "transact"}) == []
    assert ProcessAuth.VenueMessage.extract(%{"table" => "execution"}) == []
    assert ProcessAuth.VenueMessage.extract(%{"table" => "wallet"}) == []
  end

  test ".extract/2 returns an unhandled message for unknown tables" do
    assert [msg | []] = ProcessAuth.VenueMessage.extract(%{"table" => "idontexist"})
    assert %ProcessAuth.Messages.Unhandled{} = msg
  end
end
