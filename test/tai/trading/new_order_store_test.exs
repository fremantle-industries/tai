defmodule Tai.Trading.NewOrderStoreTest do
  use ExUnit.Case
  doctest Tai.Trading.NewOrderStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @venue_order_id "abc123"
  @venue_created_at Timex.now()
  @price Decimal.new(11)
  @avg_price Decimal.new(10)
  @cumulative_qty Decimal.new(1)
  @leaves_qty Decimal.new(2)
  @updated_at Timex.now()
  @venue_updated_at Timex.now()

  describe ".add" do
    test "enqueues order submissions" do
      submission = build_submission()

      assert {:ok, %Tai.Trading.Order{} = order} = Tai.Trading.NewOrderStore.add(submission)
      assert order.status == :enqueued
    end
  end

  describe ".skip" do
    test "updates the status & leaves qty" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {old, updated}} = Tai.Trading.NewOrderStore.skip(order.client_id)

      assert old.status == :enqueued
      assert updated.status == :skip
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error tuple when the order can't be found" do
      assert Tai.Trading.NewOrderStore.skip("not found") == {:error, :not_found}
    end

    test "returns an error tuple when the current status is not enqueued" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:error, reason} = Tai.Trading.NewOrderStore.skip(order.client_id)
      assert reason == {:invalid_status, :open, :enqueued}
    end
  end

  describe ".create_error" do
    test "updates the status, leaves qty & error reason" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.create_error(order.client_id, "nonce error")

      assert old.status == :enqueued
      assert updated.status == :create_error
      assert updated.error_reason == "nonce error"
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error tuple when the order can't be found" do
      assert Tai.Trading.NewOrderStore.create_error("not found", "nonce error") ==
               {:error, :not_found}
    end

    test "returns an error tuple when the current status is not enqueued" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)
      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.skip(order.client_id)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.create_error(order.client_id, "nonce error")

      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".expire" do
    test "updates the status & expire attributes" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.expire(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert old.status == :enqueued
      assert updated.status == :expired
      assert updated.venue_order_id == @venue_order_id
      assert updated.venue_created_at == @venue_created_at
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == @leaves_qty
    end

    test "returns an error tuple when the order can't be found" do
      assert {:error, :not_found} =
               Tai.Trading.NewOrderStore.expire(
                 "not found",
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )
    end

    test "returns an error tuple when the current status is not enqueued" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)
      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.skip(order.client_id)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.expire(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".open" do
    test "updates the status & open attributes" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert old.status == :enqueued
      assert updated.status == :open
      assert updated.venue_order_id == @venue_order_id
      assert updated.venue_created_at == @venue_created_at
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == @leaves_qty
    end

    test "returns an error tuple when the order can't be found" do
      assert {:error, :not_found} =
               Tai.Trading.NewOrderStore.open(
                 "not found",
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )
    end

    test "returns an error tuple when the current status is not enqueued" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert reason == {:invalid_status, :open, :enqueued}
    end
  end

  describe ".fill" do
    test "returns on ok tuple with the old & updated order" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.fill(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty
               )

      assert old.status == :enqueued
      assert updated.status == :filled
      assert updated.venue_order_id == @venue_order_id
      assert updated.venue_created_at == @venue_created_at
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error tuple when the order can't be found" do
      assert {:error, :not_found} =
               Tai.Trading.NewOrderStore.fill(
                 "not found",
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty
               )
    end

    test "returns an error tuple when the current status is not enqueued" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)
      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.skip(order.client_id)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.fill(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty
               )

      assert reason == {:invalid_status, :skip, :enqueued}
    end
  end

  describe ".passsive_fill" do
    test "returns on ok tuple with the old & updated order" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.passive_fill(
                 order.client_id,
                 @venue_updated_at,
                 @avg_price,
                 @cumulative_qty
               )

      assert old.status == :open
      assert updated.status == :filled
      assert updated.venue_updated_at == @venue_updated_at
      assert updated.avg_price == @avg_price
      assert updated.cumulative_qty == @cumulative_qty
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error tuple when the order can't be found" do
      assert {:error, :not_found} =
               Tai.Trading.NewOrderStore.passive_fill(
                 "not found",
                 @venue_updated_at,
                 @avg_price,
                 @cumulative_qty
               )
    end

    test "returns an error tuple when the current status can't be filled" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)
      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.skip(order.client_id)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.passive_fill(
                 order.client_id,
                 @venue_updated_at,
                 @avg_price,
                 @cumulative_qty
               )

      assert reason ==
               {:invalid_status, :skip,
                [:open, :pending_amend, :pending_cancel, :amend_error, :cancel_error]}
    end
  end

  describe ".pend_amend" do
    test "returns on ok tuple with the old & updated order" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.pend_amend(order.client_id, @updated_at)

      assert old.status == :open
      assert updated.status == :pending_amend
      assert updated.error_reason == nil
      assert updated.updated_at == @updated_at
    end

    test "clears the error reason" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.pend_amend(order.client_id, @updated_at)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.amend_error(order.client_id, "server unavailable")

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.pend_amend(order.client_id, @updated_at)

      assert old.error_reason == "server unavailable"
      assert updated.error_reason == nil
    end

    test "returns an error tuple when the order can't be found" do
      assert Tai.Trading.NewOrderStore.pend_amend("not found", @updated_at) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the current status is not open" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)
      assert {:error, reason} = Tai.Trading.NewOrderStore.pend_amend(order.client_id, @updated_at)
      assert reason == {:invalid_status, :enqueued, [:open, :amend_error]}
    end
  end

  describe ".amend_error" do
    test "returns on ok tuple with the old & updated order" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.pend_amend(order.client_id, @updated_at)

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.amend_error(order.client_id, "server unavailable")

      assert old.status == :pending_amend
      assert updated.status == :amend_error
    end

    test "returns an error tuple when the order can't be found" do
      assert Tai.Trading.NewOrderStore.amend_error("not found", "server unavailable") ==
               {:error, :not_found}
    end

    test "returns an error tuple when the current status is not pending_amend" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.amend_error(order.client_id, "server unavailable")

      assert reason == {:invalid_status, :enqueued, :pending_amend}
    end
  end

  describe ".amend" do
    test "updates the status & reopen attributes" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.pend_amend(order.client_id, @updated_at)

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.amend(
                 order.client_id,
                 @venue_updated_at,
                 @price,
                 @leaves_qty
               )

      assert old.status == :pending_amend
      assert updated.status == :open
      assert updated.venue_updated_at == @venue_updated_at
      assert updated.price == @price
      assert updated.leaves_qty == @leaves_qty
    end

    test "returns an error tuple when the order can't be found" do
      assert {:error, :not_found} =
               Tai.Trading.NewOrderStore.amend(
                 "not found",
                 @venue_updated_at,
                 @price,
                 @leaves_qty
               )
    end

    test "returns an error tuple when the current status is not pending_amend" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.amend(
                 order.client_id,
                 @venue_updated_at,
                 @price,
                 @leaves_qty
               )

      assert reason == {:invalid_status, :enqueued, :pending_amend}
    end
  end

  describe ".pend_cancel" do
    test "returns on ok tuple with the old & updated order" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.pend_cancel(order.client_id, @updated_at)

      assert old.status == :open
      assert updated.status == :pending_cancel
      assert updated.updated_at == @updated_at
    end

    test "returns an error tuple when the order can't be found" do
      assert Tai.Trading.NewOrderStore.pend_cancel("not found", @updated_at) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the current status is not open" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.pend_cancel(order.client_id, @updated_at)

      assert reason == {:invalid_status, :enqueued, :open}
    end
  end

  describe ".cancel_error" do
    test "returns on ok tuple with the old & updated order" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.pend_cancel(order.client_id, @updated_at)

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.cancel_error(order.client_id, "server unavailable")

      assert old.status == :pending_cancel
      assert updated.status == :cancel_error
      assert updated.error_reason == "server unavailable"
    end

    test "returns an error tuple when the order can't be found" do
      assert Tai.Trading.NewOrderStore.cancel_error("not found", "server unavailable") ==
               {:error, :not_found}
    end

    test "returns an error tuple when the current status is not pending_cancel" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.cancel_error(order.client_id, "server unavailable")

      assert reason == {:invalid_status, :enqueued, :pending_cancel}
    end
  end

  describe ".passive_cancel" do
    test "returns on ok tuple with the old & updated order" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.passive_cancel(order.client_id, @venue_updated_at)

      assert old.status == :open
      assert updated.status == :canceled
      assert updated.venue_updated_at == @venue_updated_at
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error tuple when the order can't be found" do
      assert Tai.Trading.NewOrderStore.passive_cancel("not found", @venue_updated_at) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the current status is cancel" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.passive_cancel(order.client_id, @venue_updated_at)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.passive_cancel(order.client_id, @venue_updated_at)

      assert reason ==
               {:invalid_status, :canceled,
                [
                  :enqueued,
                  :open,
                  :expired,
                  :filled,
                  :pending_cancel,
                  :pending_amend,
                  :cancel,
                  :amend
                ]}
    end
  end

  describe ".cancel" do
    test "returns on ok tuple with the old & updated order" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:ok, {_, _}} =
               Tai.Trading.NewOrderStore.open(
                 order.client_id,
                 @venue_order_id,
                 @venue_created_at,
                 @avg_price,
                 @cumulative_qty,
                 @leaves_qty
               )

      assert {:ok, {_, _}} = Tai.Trading.NewOrderStore.pend_cancel(order.client_id, @updated_at)

      assert {:ok, {old, updated}} =
               Tai.Trading.NewOrderStore.cancel(order.client_id, @venue_updated_at)

      assert old.status == :pending_cancel
      assert updated.status == :canceled
      assert updated.venue_updated_at == @venue_updated_at
      assert updated.leaves_qty == Decimal.new(0)
    end

    test "returns an error tuple when the order can't be found" do
      assert Tai.Trading.NewOrderStore.cancel("not found", @venue_updated_at) ==
               {:error, :not_found}
    end

    test "returns an error tuple when the current status is not pending_cancel" do
      submission = build_submission()

      assert {:ok, order} = Tai.Trading.NewOrderStore.add(submission)

      assert {:error, reason} =
               Tai.Trading.NewOrderStore.cancel(order.client_id, @venue_updated_at)

      assert reason == {:invalid_status, :enqueued, :pending_cancel}
    end
  end

  describe ".find_by_client_id" do
    test "returns an ok tuple with the order " do
      {:ok, order} = submit_order()

      assert {:ok, ^order} = Tai.Trading.NewOrderStore.find_by_client_id(order.client_id)
    end

    test "returns an error tuple when no match was found" do
      assert Tai.Trading.NewOrderStore.find_by_client_id("not found") == {:error, :not_found}
    end
  end

  test ".all returns a list of current orders" do
    assert Tai.Trading.NewOrderStore.all() == []

    {:ok, order} = submit_order()

    assert Tai.Trading.NewOrderStore.all() == [order]
  end

  test ".count returns the total number of orders" do
    assert Tai.Trading.NewOrderStore.count() == 0

    {:ok, _} = submit_order()

    assert Tai.Trading.NewOrderStore.count() == 1
  end

  defp submit_order do
    %Tai.Trading.OrderSubmissions.BuyLimitFok{
      venue_id: :test_exchange_a,
      account_id: :main,
      product_symbol: :btc_usd,
      price: Decimal.new("100.1"),
      qty: Decimal.new("1.1")
    }
    |> Tai.Trading.NewOrderStore.add()
  end

  defp build_submission do
    struct(Tai.Trading.OrderSubmissions.BuyLimitGtc, %{
      price: Decimal.new(1000),
      qty: Decimal.new(1)
    })
  end
end
