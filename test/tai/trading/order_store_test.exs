defmodule Tai.Trading.OrderStoreTest do
  use ExUnit.Case
  doctest Tai.Trading.OrderStore
  alias Tai.Trading.OrderStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @venue_order_id "abc123"
  @price Decimal.new(11)
  @avg_price Decimal.new(10)
  @cumulative_qty Decimal.new(1)
  @leaves_qty Decimal.new(5)
  @updated_at Timex.now()
  @last_received_at Timex.now()
  @last_venue_timestamp Timex.now()

  test ".enqueue creates an order from the submission" do
    submission = build_submission()

    assert {:ok, order} = OrderStore.enqueue(submission)
    assert order.status == :enqueued
  end

  describe ".skip" do
    test "updates whitelisted attributes " do
      assert {:ok, order} = enqueue()
      assert {:ok, {old, updated}} = OrderStore.skip(order.client_id)

      assert old.status == :enqueued
      assert updated.status == :skip
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.skip("not found") == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:ok, {_, _}} =
               OrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert {:error, reason} = OrderStore.skip(order.client_id)
      assert reason == {:invalid_status, :open, :enqueued}
    end
  end

  describe ".accept_create" do
    test "updates whitelisted attributes " do
      assert {:ok, order} = enqueue()

      assert {:ok, {old, updated}} =
               OrderStore.accept_create(
                 order.client_id,
                 @venue_order_id,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :enqueued
      assert updated.status == :create_accepted
      assert updated.venue_order_id == @venue_order_id
      assert updated.last_received_at == @last_received_at
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert {:error, :not_found} =
               OrderStore.accept_create(
                 "not found",
                 @venue_order_id,
                 @last_received_at,
                 @last_venue_timestamp
               )
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = OrderStore.skip(order.client_id)

      assert {:error, reason} =
               OrderStore.accept_create(
                 order.client_id,
                 @venue_order_id,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".open" do
    test "updates whitelisted attributes " do
      assert {:ok, order} = enqueue()

      assert {:ok, {old, updated}} =
               OrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :enqueued
      assert updated.status == :open
      assert updated.venue_order_id == @venue_order_id
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == @leaves_qty
      assert updated.qty == Decimal.add(@cumulative_qty, @leaves_qty)
      assert updated.last_received_at == @last_received_at
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert {:error, :not_found} =
               OrderStore.open(
                 "not found",
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )
    end

    test "returns an error when the current status is not enqueued" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = OrderStore.skip(order.client_id)

      assert {:error, reason} =
               OrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason == {:invalid_status, :skip, [:enqueued, :create_accepted]}
    end
  end

  describe ".fill" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()

      assert {:ok, {old, updated}} =
               OrderStore.fill(
                 order.client_id,
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :enqueued
      assert updated.status == :filled
      assert updated.venue_order_id == @venue_order_id
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == Decimal.new(0)
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert {:error, :not_found} =
               OrderStore.fill(
                 "not found",
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = OrderStore.skip(order.client_id)

      assert {:error, reason} =
               OrderStore.fill(
                 order.client_id,
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".expire" do
    test "updates whitelisted attributes " do
      assert {:ok, order} = enqueue()

      assert {:ok, {old, updated}} =
               OrderStore.expire(
                 order.client_id,
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :enqueued
      assert updated.status == :expired
      assert updated.venue_order_id == @venue_order_id
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == @leaves_qty
      assert updated.last_received_at == @last_received_at
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.expire(
               "not found",
               @venue_order_id,
               @avg_price,
               @cumulative_qty,
               @leaves_qty,
               @last_received_at,
               @last_venue_timestamp
             ) == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = OrderStore.skip(order.client_id)

      assert {:error, reason} =
               OrderStore.expire(
                 order.client_id,
                 @venue_order_id,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".reject" do
    test "updates whitelisted attributes" do
      assert {:ok, order} = enqueue()

      assert {:ok, {old, updated}} =
               OrderStore.reject(
                 order.client_id,
                 @venue_order_id,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :enqueued
      assert updated.status == :rejected
      assert updated.venue_order_id == @venue_order_id
      assert updated.leaves_qty == Decimal.new(0)
      assert updated.last_received_at == @last_received_at
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.reject(
               "not found",
               @venue_order_id,
               @last_received_at,
               @last_venue_timestamp
             ) == {:error, :not_found}
    end

    test "returns an error tuple when the current status is invalid" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = OrderStore.skip(order.client_id)

      assert {:error, reason} =
               OrderStore.reject(
                 order.client_id,
                 @venue_order_id,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".create_error" do
    test "updates whitelisted attributes " do
      assert {:ok, order} = enqueue()

      assert {:ok, {old, updated}} =
               OrderStore.create_error(
                 order.client_id,
                 "nonce error",
                 @last_received_at
               )

      assert old.status == :enqueued
      assert updated.status == :create_error
      assert updated.error_reason == "nonce error"
      assert updated.leaves_qty == Decimal.new(0)
      assert updated.last_received_at == @last_received_at
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.create_error("not found", "nonce error", @last_received_at) ==
               {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = OrderStore.skip(order.client_id)

      assert {:error, reason} =
               OrderStore.create_error(
                 order.client_id,
                 "nonce error",
                 @last_received_at
               )

      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".pend_amend" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)

      assert {:ok, {old, updated}} = OrderStore.pend_amend(order.client_id, @updated_at)
      assert old.status == :open
      assert updated.status == :pending_amend
      assert updated.updated_at == @updated_at
    end

    test "resets error reason" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)
      assert {:ok, {_, _}} = OrderStore.pend_amend(order.client_id, @updated_at)

      assert {:ok, {_, _}} =
               OrderStore.amend_error(
                 order.client_id,
                 "server unavailable",
                 @last_received_at
               )

      assert {:ok, {old, updated}} = OrderStore.pend_amend(order.client_id, @updated_at)
      assert old.error_reason == "server unavailable"
      assert updated.error_reason == nil
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.pend_amend("not found", @updated_at) == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} = OrderStore.pend_amend(order.client_id, @updated_at)
      assert reason == {:invalid_status, :enqueued, [:open, :amend_error]}
    end
  end

  describe ".amend" do
    test "updates whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)
      assert {:ok, {_, _}} = OrderStore.pend_amend(order.client_id, @updated_at)

      assert {:ok, {old, updated}} =
               OrderStore.amend(
                 order.client_id,
                 @price,
                 @leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :pending_amend
      assert updated.status == :open
      assert updated.price == @price
      assert updated.leaves_qty == @leaves_qty
      assert updated.last_received_at == @last_received_at
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.amend(
               "not found",
               @price,
               @leaves_qty,
               @last_received_at,
               @last_venue_timestamp
             ) == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} =
               OrderStore.amend(
                 order.client_id,
                 @price,
                 @leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason == {:invalid_status, :enqueued, :pending_amend}
    end
  end

  describe ".amend_error" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)
      assert {:ok, {_, _}} = OrderStore.pend_amend(order.client_id, @updated_at)

      assert {:ok, {old, updated}} =
               OrderStore.amend_error(
                 order.client_id,
                 "server unavailable",
                 @last_received_at
               )

      assert old.status == :pending_amend
      assert updated.status == :amend_error
      assert updated.last_received_at == @last_received_at
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.amend_error(
               "not found",
               "server unavailable",
               @last_received_at
             ) == {:error, :not_found}
    end

    test "returns an error when the current status is not pending_amend" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} =
               OrderStore.amend_error(
                 order.client_id,
                 "server unavailable",
                 @last_received_at
               )

      assert reason == {:invalid_status, :enqueued, :pending_amend}
    end
  end

  describe ".pend_cancel" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)

      assert {:ok, {old, updated}} = OrderStore.pend_cancel(order.client_id, @updated_at)
      assert old.status == :open
      assert updated.status == :pending_cancel
      assert updated.updated_at == @updated_at
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.pend_cancel("not found", @updated_at) == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} = OrderStore.pend_cancel(order.client_id, @updated_at)
      assert reason == {:invalid_status, :enqueued, :open}
    end
  end

  describe ".accept_cancel" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)
      assert {:ok, {_, _}} = OrderStore.pend_cancel(order.client_id, @updated_at)

      assert {:ok, {old, updated}} =
               OrderStore.accept_cancel(order.client_id, @last_venue_timestamp)

      assert old.status == :pending_cancel
      assert updated.status == :cancel_accepted
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.accept_cancel("not found", @last_venue_timestamp) ==
               {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} = OrderStore.accept_cancel(order.client_id, @last_venue_timestamp)
      assert reason == {:invalid_status, :enqueued, :pending_cancel}
    end
  end

  describe ".cancel" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)
      assert {:ok, {_, _}} = OrderStore.pend_cancel(order.client_id, @updated_at)

      assert {:ok, {old, updated}} = OrderStore.cancel(order.client_id, @last_venue_timestamp)
      assert old.status == :pending_cancel
      assert updated.status == :canceled
      assert updated.last_venue_timestamp == @last_venue_timestamp
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.cancel("not found", @last_venue_timestamp) == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} = OrderStore.cancel(order.client_id, @last_venue_timestamp)
      assert reason == {:invalid_status, :enqueued, :pending_cancel}
    end
  end

  describe ".cancel_error" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)
      assert {:ok, {_, _}} = OrderStore.pend_cancel(order.client_id, @updated_at)

      assert {:ok, {old, updated}} =
               OrderStore.cancel_error(
                 order.client_id,
                 "server unavailable",
                 @last_received_at
               )

      assert old.status == :pending_cancel
      assert updated.status == :cancel_error
      assert updated.error_reason == "server unavailable"
      assert updated.last_received_at == @last_received_at
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.cancel_error(
               "not found",
               "server unavailable",
               @last_received_at
             ) ==
               {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} =
               OrderStore.cancel_error(order.client_id, "server unavailable", @last_received_at)

      assert reason == {:invalid_status, :enqueued, :pending_cancel}
    end
  end

  describe ".passive_fill" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)

      assert {:ok, {old, updated}} =
               OrderStore.passive_fill(
                 order.client_id,
                 @cumulative_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :open
      assert updated.status == :filled
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == Decimal.new(0)
      assert updated.last_received_at == @last_received_at
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.passive_fill(
               "not found",
               @cumulative_qty,
               @last_received_at,
               @last_venue_timestamp
             ) == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = OrderStore.skip(order.client_id)

      assert {:error, reason} =
               OrderStore.passive_fill(
                 order.client_id,
                 @cumulative_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason ==
               {:invalid_status, :skip,
                [:open, :pending_amend, :pending_cancel, :amend_error, :cancel_error]}
    end
  end

  describe ".passive_partial_fill" do
    @updated_leaves_qty Decimal.new(2)

    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)

      assert {:ok, {old, updated}} =
               OrderStore.passive_partial_fill(
                 order.client_id,
                 @avg_price,
                 @cumulative_qty,
                 @updated_leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :open
      assert updated.status == :open
      assert updated.last_venue_timestamp == @last_venue_timestamp
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == Decimal.new(2)
    end

    test "returns an error when the order can't be found" do
      assert {:error, :not_found} =
               OrderStore.passive_partial_fill(
                 "not found",
                 @avg_price,
                 @cumulative_qty,
                 @updated_leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} =
               OrderStore.passive_partial_fill(
                 order.client_id,
                 @avg_price,
                 @cumulative_qty,
                 @updated_leaves_qty,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason ==
               {:invalid_status, :enqueued,
                [:open, :pending_amend, :pending_cancel, :amend_error, :cancel_error]}
    end
  end

  describe ".passive_cancel" do
    test "updates the whitelisted attributes" do
      assert {:ok, order} = enqueue()
      assert {:ok, {_, _}} = open(order)

      assert {:ok, {old, updated}} =
               OrderStore.passive_cancel(
                 order.client_id,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert old.status == :open
      assert updated.status == :canceled
      assert updated.leaves_qty == Decimal.new(0)
      assert updated.last_received_at == @last_received_at
      assert updated.last_venue_timestamp == @last_venue_timestamp
    end

    test "returns an error when the order can't be found" do
      assert OrderStore.passive_cancel(
               "not found",
               @last_received_at,
               @last_venue_timestamp
             ) == {:error, :not_found}
    end

    test "returns an error when the current status is invalid" do
      assert {:ok, order} = enqueue()

      assert {:error, reason} =
               OrderStore.passive_cancel(
                 order.client_id,
                 @last_received_at,
                 @last_venue_timestamp
               )

      assert reason ==
               {:invalid_status, :enqueued,
                [
                  :open,
                  :expired,
                  :filled,
                  :pending_amend,
                  :amend,
                  :amend_error,
                  :pending_cancel,
                  :cancel_accepted
                ]}
    end
  end

  describe ".find_by_client_id" do
    test "returns the order " do
      {:ok, order} = enqueue()
      assert {:ok, ^order} = OrderStore.find_by_client_id(order.client_id)
    end

    test "returns an error when no match was found" do
      assert OrderStore.find_by_client_id("not found") == {:error, :not_found}
    end
  end

  test ".all returns a list of current orders" do
    assert OrderStore.all() == []
    {:ok, order} = enqueue()
    assert OrderStore.all() == [order]
  end

  test ".count returns the total number of orders" do
    assert OrderStore.count() == 0
    {:ok, _} = enqueue()
    assert OrderStore.count() == 1
  end

  defp enqueue, do: build_submission() |> OrderStore.enqueue()

  defp open(order) do
    OrderStore.open(
      order.client_id,
      @venue_order_id,
      @avg_price,
      @cumulative_qty,
      @leaves_qty,
      Timex.now(),
      Timex.now()
    )
  end

  defp build_submission do
    struct(Tai.Trading.OrderSubmissions.BuyLimitGtc,
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1")
    )
  end
end
