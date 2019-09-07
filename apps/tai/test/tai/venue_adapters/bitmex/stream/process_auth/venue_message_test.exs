defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.VenueMessageTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Bitmex.Stream.ProcessAuth

  defmodule TestProvider do
    def update_orders(data), do: data
  end

  test ".extract/2 returns a list of order update messages" do
    assert ProcessAuth.VenueMessage.extract(
             %{
               "table" => "order",
               "action" => "update",
               "data" => ["update_order"]
             },
             TestProvider
           ) == ["update_order"]
  end

  test ".extract/2 returns an empty list for noop tables" do
    assert ProcessAuth.VenueMessage.extract(%{"table" => "order", "action" => "insert"}) == []
    assert ProcessAuth.VenueMessage.extract(%{"table" => "transact"}) == []
    assert ProcessAuth.VenueMessage.extract(%{"table" => "execution"}) == []
    assert ProcessAuth.VenueMessage.extract(%{"table" => "wallet"}) == []
    assert ProcessAuth.VenueMessage.extract(%{"table" => "margin"}) == []
    assert ProcessAuth.VenueMessage.extract(%{"table" => "position"}) == []
  end

  test ".extract/2 returns a list with an unhandled message for other tables" do
    assert [msg | []] = ProcessAuth.VenueMessage.extract(%{"table" => "idontexist"})
    assert %ProcessAuth.Messages.Unhandled{} = msg
  end
end
