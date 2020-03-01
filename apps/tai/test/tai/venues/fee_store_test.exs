defmodule Tai.Venues.FeeStoreTest do
  use ExUnit.Case, async: false
  doctest Tai.Venues.FeeStore

  setup do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  @fee_info %Tai.Venues.FeeInfo{
    venue_id: :my_exchange,
    credential_id: :main_credential,
    symbol: :btc_usdt,
    maker: Decimal.new("0.1"),
    maker_type: Tai.Venues.FeeInfo.percent(),
    taker: Decimal.new("0.1"),
    taker_type: Tai.Venues.FeeInfo.percent()
  }

  describe "#upsert" do
    test "insert the fee info into the ETS table" do
      assert Tai.Venues.FeeStore.upsert(@fee_info) == :ok

      assert [{{:my_exchange, :main_credential, :btc_usdt}, fee_info}] =
               :ets.lookup(Tai.Venues.FeeStore, {:my_exchange, :main_credential, :btc_usdt})

      assert fee_info == @fee_info
    end
  end

  describe "#clear" do
    test "removes the existing items in the ETS table" do
      assert Tai.Venues.FeeStore.upsert(@fee_info) == :ok
      assert Tai.Venues.FeeStore.count() == 1

      assert Tai.Venues.FeeStore.clear() == :ok
      assert Tai.Venues.FeeStore.count() == 0
    end
  end

  describe "#all" do
    test "returns a list of all the existing items" do
      assert Tai.Venues.FeeStore.all() == []

      assert Tai.Venues.FeeStore.upsert(@fee_info) == :ok

      assert [fee_info] = Tai.Venues.FeeStore.all()
      assert fee_info == @fee_info
    end
  end

  describe "#find_by" do
    test "returns the fee info in an ok tuple" do
      assert Tai.Venues.FeeStore.upsert(@fee_info) == :ok

      assert {:ok, fee_info} =
               Tai.Venues.FeeStore.find_by(
                 venue_id: :my_exchange,
                 credential_id: :main_credential,
                 symbol: :btc_usdt
               )

      assert fee_info == @fee_info
    end

    test "returns an error tuple when not found" do
      assert Tai.Venues.FeeStore.find_by(
               venue_id: :my_exchange,
               credential_id: :main_credential,
               symbol: :idontexist
             ) == {:error, :not_found}
    end
  end
end
