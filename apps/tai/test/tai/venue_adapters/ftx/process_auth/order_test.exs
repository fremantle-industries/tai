defmodule Tai.VenueAdapters.Ftx.Stream.ProcessAuth.OrderTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Assertions.Event
  alias Tai.VenueAdapters.Ftx.Stream.ProcessAuth
  # alias Tai.VenueAdapters.OkEx.ClientId

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tzdata)
    {:ok, _} = Application.ensure_all_started(:tai)
    start_supervised!({ProcessAuth, [venue: :my_venue]})
    :ok
  end

  # test "broadcasts an event when the order can't be found" do
  #   TaiEvents.firehose_subscribe()
  #   # accept_create_client_id = Ecto.UUID.generate()
  #   # open_client_id = Ecto.UUID.generate()
  #   # canceled_client_id = Ecto.UUID.generate()
  #   # partially_filled_client_id = Ecto.UUID.generate()
  #   # filled_client_id = Ecto.UUID.generate()

  #   no_client_id_order = %{
  #     "clientId" => nil,
  #     "id" => 123,
  #     "market" => "BTC/USD",
  #     "createdAt" => "2021-03-21T03:36:35.838931+00:00",
  #     "status" => "new",
  #     "type" => "limit"
  #     # "avgFillPrice" => nil,
  #     # "filledSize" => 0.0,
  #     # "ioc" => false,
  #     # "liquidation" => false,
  #     # "postOnly" => false,
  #     # "price" => 4.0e4,
  #     # "reduceOnly" => false,
  #     # "remainingSize" => 0.0001,
  #     # "side" => "buy",
  #     # "size" => 0.0001,
  #   }

  #   :my_venue
  #   |> ProcessAuth.process_name()
  #   |> GenServer.cast({no_client_id_order, :ignore})

  #   assert_event(
  #     %Tai.Events.OrderUpdateNotFound{} = order_update_not_found_event
  #   )
  # end

  test "foo" do
  end
end
