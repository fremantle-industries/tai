defmodule Tai.Trading.Orders.AmendTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Mock
  alias Tai.TestSupport.Mocks
  alias Mocks.Responses.Orders.GoodTillCancel

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})

  setup do
    start_supervised!(Mocks.Server)
    start_supervised!({TaiEvents, 1})
    start_supervised!({Tai.Settings, Tai.Config.parse()})
    start_supervised!(Tai.Trading.OrderStore)
    start_supervised!(Tai.Venues.VenueStore)

    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    {:buy, Tai.Trading.OrderSubmissions.BuyLimitGtc},
    {:sell, Tai.Trading.OrderSubmissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type
    @original_price Decimal.new(100)
    @original_qty Decimal.new(1)

    describe "#{side} success with an open order" do
      setup do
        {:ok, enqueued_order} =
          @submission_type
          |> Support.OrderSubmissions.build_with_callback(%{
            venue_id: @venue,
            credential_id: @credential,
            price: @original_price,
            qty: @original_qty
          })
          |> Tai.Trading.OrderStore.enqueue()

        {:ok, {_, open_order}} =
          %Tai.Trading.OrderStore.Actions.Open{
            client_id: enqueued_order.client_id,
            venue_order_id: @venue_order_id,
            cumulative_qty: Decimal.new(0),
            leaves_qty: @original_qty,
            last_received_at: Timex.now(),
            last_venue_timestamp: Timex.now()
          }
          |> Tai.Trading.OrderStore.update()

        {:ok, %{order: open_order}}
      end

      test "pends the order while amending then updates price & leaves_qty once amended", %{
        order: open_order
      } do
        amend_price = Decimal.new("105.5")
        amend_qty = Decimal.new(10)
        GoodTillCancel.amend_price_and_qty(open_order, amend_price, amend_qty)
        TaiEvents.firehose_subscribe()

        assert {:ok, %Tai.Trading.Order{} = returned_order} =
                 Tai.Trading.Orders.amend(open_order, %{
                   price: amend_price,
                   qty: amend_qty
                 })

        assert returned_order.status == :pending_amend
        assert returned_order.price == @original_price
        assert returned_order.leaves_qty == @original_qty
        assert returned_order.qty == @original_qty

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :open},
          %Tai.Trading.Order{status: :pending_amend} = pending_amend_order
        }

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :pending_amend},
          %Tai.Trading.Order{status: :open} = amended_order
        }

        assert pending_amend_order.price == @original_price
        assert pending_amend_order.leaves_qty == @original_qty
        assert pending_amend_order.qty == @original_qty
        assert %DateTime{} = pending_amend_order.updated_at

        assert amended_order.price == amend_price
        assert amended_order.leaves_qty == amend_qty
        assert amended_order.qty == amend_qty
        assert %DateTime{} = amended_order.updated_at
        assert Timex.compare(amended_order.updated_at, pending_amend_order.updated_at) == 1
        assert %DateTime{} = amended_order.last_received_at
        assert %DateTime{} = amended_order.last_venue_timestamp
        assert amended_order.last_venue_timestamp != pending_amend_order.last_venue_timestamp
        assert amended_order.last_received_at != pending_amend_order.last_received_at
      end
    end

    describe "#{side} success with an amend_error order" do
      setup do
        {:ok, enqueued_order} =
          @submission_type
          |> Support.OrderSubmissions.build_with_callback(%{
            venue_id: @venue,
            credential_id: @credential,
            price: @original_price,
            qty: @original_qty
          })
          |> Tai.Trading.OrderStore.enqueue()

        {:ok, {_, _}} =
          %Tai.Trading.OrderStore.Actions.Open{
            client_id: enqueued_order.client_id,
            venue_order_id: @venue_order_id,
            cumulative_qty: Decimal.new(0),
            leaves_qty: @original_qty,
            last_received_at: Timex.now(),
            last_venue_timestamp: Timex.now()
          }
          |> Tai.Trading.OrderStore.update()

        {:ok, {_, _}} =
          %Tai.Trading.OrderStore.Actions.PendAmend{client_id: enqueued_order.client_id}
          |> Tai.Trading.OrderStore.update()

        {:ok, {_, amend_error_order}} =
          %Tai.Trading.OrderStore.Actions.AmendError{
            client_id: enqueued_order.client_id,
            reason: "Invalid nonce",
            last_received_at: Timex.now()
          }
          |> Tai.Trading.OrderStore.update()

        {:ok, %{order: amend_error_order}}
      end

      test "pends the order while amending then updates price & leaves_qty once amended", %{
        order: open_order
      } do
        amend_price = Decimal.new("105.5")
        amend_qty = Decimal.new(10)
        GoodTillCancel.amend_price_and_qty(open_order, amend_price, amend_qty)
        TaiEvents.firehose_subscribe()

        assert {:ok, %Tai.Trading.Order{} = returned_order} =
                 Tai.Trading.Orders.amend(open_order, %{
                   price: amend_price,
                   qty: amend_qty
                 })

        assert returned_order.status == :pending_amend
        assert returned_order.price == @original_price
        assert returned_order.leaves_qty == @original_qty
        assert returned_order.qty == @original_qty
        assert returned_order.error_reason == nil

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :amend_error},
          %Tai.Trading.Order{status: :pending_amend} = pending_amend_order
        }

        assert_receive {
          :callback_fired,
          %Tai.Trading.Order{status: :pending_amend},
          %Tai.Trading.Order{status: :open} = amended_order
        }

        assert pending_amend_order.price == @original_price
        assert pending_amend_order.leaves_qty == @original_qty
        assert pending_amend_order.qty == @original_qty
        assert %DateTime{} = pending_amend_order.updated_at

        assert amended_order.price == amend_price
        assert amended_order.leaves_qty == amend_qty
        assert amended_order.qty == amend_qty
        assert %DateTime{} = amended_order.updated_at
        assert Timex.compare(amended_order.updated_at, pending_amend_order.updated_at) == 1
        assert %DateTime{} = amended_order.last_received_at
        assert %DateTime{} = amended_order.last_venue_timestamp
        assert amended_order.last_venue_timestamp != pending_amend_order.last_venue_timestamp
        assert amended_order.last_received_at != pending_amend_order.last_received_at
      end
    end
  end)
end
