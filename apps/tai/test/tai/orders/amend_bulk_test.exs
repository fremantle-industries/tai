defmodule Tai.Orders.AmendBulkTest do
  use ExUnit.Case, async: false
  import Tai.TestSupport.Helpers
  import Tai.TestSupport.Mock
  import Support.Orders
  alias Tai.TestSupport.Mocks
  alias Mocks.Responses.Orders.GoodTillCancel

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @pending_venue_order_id "df8e6bd0-a40a-42fb-8fea-pending"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})

  setup do
    setup_orders(&start_supervised!/1)
    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    {:buy, Tai.Orders.OrderSubmissions.BuyLimitGtc},
    {:sell, Tai.Orders.OrderSubmissions.SellLimitGtc}
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
          |> Tai.Orders.OrderStore.enqueue()

        {:ok, {_, open_order}} =
          %Tai.Orders.Transitions.Open{
            client_id: enqueued_order.client_id,
            venue_order_id: @venue_order_id,
            cumulative_qty: Decimal.new(0),
            leaves_qty: @original_qty,
            last_received_at: Tai.Time.monotonic_time(),
            last_venue_timestamp: Timex.now()
          }
          |> Tai.Orders.OrderStore.update()

        {:ok, enqueued_pend_order} =
          @submission_type
          |> Support.OrderSubmissions.build(%{
            price: @original_price,
            qty: @original_qty,
            order_updated_callback: fire_order_callback(self())
          })
          |> Tai.Orders.OrderStore.enqueue()

        {:ok, {_, open_pend_order}} =
          %Tai.Orders.Transitions.Open{
            client_id: enqueued_pend_order.client_id,
            venue_order_id: @pending_venue_order_id,
            cumulative_qty: Decimal.new(0),
            leaves_qty: @original_qty,
            last_received_at: Tai.Time.monotonic_time(),
            last_venue_timestamp: Timex.now()
          }
          |> Tai.Orders.OrderStore.update()

        {:ok, {_, pending_order}} =
          %Tai.Orders.Transitions.PendAmend{client_id: open_pend_order.client_id}
          |> Tai.Orders.OrderStore.update()

        {:ok, %{order: open_order, pending_order: pending_order}}
      end

      test "pends the order while amending then updates price & leaves_qty once amended", %{
        order: open_order,
        pending_order: pending_order
      } do
        amend_price = Decimal.new("105.5")
        amend_qty = Decimal.new(10)

        GoodTillCancel.amend_bulk_price_and_qty([
          {open_order, %{price: amend_price, qty: amend_qty}}
        ])

        assert [{:ok, %Tai.Orders.Order{} = returned_order}, {:error, amend_error}] =
                 Tai.Orders.amend_bulk([
                   {open_order, %{price: amend_price, qty: amend_qty}},
                   {pending_order, %{price: amend_price, qty: amend_qty}}
                 ])

        # test amended order
        assert returned_order.status == :pending_amend
        assert returned_order.price == @original_price
        assert returned_order.leaves_qty == @original_qty
        assert returned_order.qty == @original_qty

        assert_receive {
          :callback_fired,
          %Tai.Orders.Order{status: :open},
          %Tai.Orders.Order{status: :pending_amend} = pending_amend_order
        }

        assert_receive {
          :callback_fired,
          %Tai.Orders.Order{status: :pending_amend},
          %Tai.Orders.Order{status: :open} = amended_order
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
        assert amended_order.last_received_at > 0
        assert %DateTime{} = amended_order.last_venue_timestamp
        assert amended_order.last_venue_timestamp != pending_amend_order.last_venue_timestamp
        assert amended_order.last_received_at != pending_amend_order.last_received_at

        # test for amend_error
        assert {:invalid_status, :pending_amend, _, %{client_id: amend_error_client_id}} =
                 amend_error

        assert amend_error_client_id == pending_order.client_id
      end
    end
  end)
end
