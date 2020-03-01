defmodule Tai.Trading.OrderStore.ActionsTest do
  use ExUnit.Case, async: false
  alias Tai.Trading.OrderStore

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    Tai.Settings.enable_send_orders!()

    :ok
  end

  test "Amend: sets qty to the sum of cumulative & leaves" do
    assert {:ok, enqueued_order} = enqueue()

    assert {:ok, {_, open_order}} =
             enqueued_order |> open(cumulative_qty: Decimal.new(5), leaves_qty: Decimal.new(4))

    assert {:ok, {_, pending_amend}} = open_order |> pend_amend()

    action =
      struct!(
        OrderStore.Actions.Amend,
        client_id: pending_amend.client_id,
        price: Decimal.new(1),
        leaves_qty: Decimal.new(1),
        last_received_at: Timex.now(),
        last_venue_timestamp: Timex.now()
      )

    assert {:ok, {old, updated}} = OrderStore.update(action)

    assert old.status == :pending_amend
    assert updated.status == :open
    assert updated.leaves_qty == Decimal.new(1)
    assert updated.cumulative_qty == Decimal.new(5)
    assert updated.qty == Decimal.new(6)
  end

  test "Cancel: sets qty to cumulative" do
    assert {:ok, enqueued_order} = enqueue()

    assert {:ok, {_, open_order}} =
             enqueued_order |> open(cumulative_qty: Decimal.new(5), leaves_qty: Decimal.new(4))

    assert {:ok, {_, pending_cancel}} = open_order |> pend_cancel()

    action =
      struct!(
        OrderStore.Actions.Cancel,
        client_id: pending_cancel.client_id,
        last_venue_timestamp: Timex.now()
      )

    assert {:ok, {old, updated}} = OrderStore.update(action)

    assert old.status == :pending_cancel
    assert updated.status == :canceled
    assert updated.leaves_qty == Decimal.new(0)
    assert updated.cumulative_qty == Decimal.new(5)
    assert updated.qty == Decimal.new(5)
  end

  defp build_submission do
    struct(Tai.Trading.OrderSubmissions.BuyLimitGtc,
      venue_id: :test_exchange_a,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1")
    )
  end

  defp enqueue, do: build_submission() |> OrderStore.enqueue()

  defp open(order, attrs) do
    cumulative_qty = attrs[:cumulative_qty] || Decimal.new(1)
    leaves_qty = attrs[:leaves_qty] || Decimal.new(1)

    %OrderStore.Actions.Open{
      client_id: order.client_id,
      venue_order_id: "venueOrderIdA",
      cumulative_qty: cumulative_qty,
      leaves_qty: leaves_qty,
      last_received_at: Timex.now(),
      last_venue_timestamp: Timex.now()
    }
    |> OrderStore.update()
  end

  defp pend_amend(order) do
    %OrderStore.Actions.PendAmend{client_id: order.client_id}
    |> OrderStore.update()
  end

  defp pend_cancel(order) do
    %OrderStore.Actions.PendCancel{client_id: order.client_id}
    |> OrderStore.update()
  end
end
