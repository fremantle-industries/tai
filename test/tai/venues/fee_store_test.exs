defmodule Tai.Venues.FeeStoreTest do
  use ExUnit.Case, async: false
  doctest Tai.Venues.FeeStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)

    fee_info = %Tai.Venues.FeeInfo{
      exchange_id: :my_exchange,
      account_id: :main_account,
      symbol: :btc_usdt,
      maker: Decimal.new("0.1"),
      maker_type: Tai.Venues.FeeInfo.percent(),
      taker: Decimal.new("0.1"),
      taker_type: Tai.Venues.FeeInfo.percent()
    }

    {:ok, %{fee_info: fee_info}}
  end

  describe "#upsert" do
    test "insert the fee info into the ETS table", %{fee_info: fee_info} do
      assert Tai.Venues.FeeStore.upsert(fee_info) == :ok

      assert [{{:my_exchange, :main_account, :btc_usdt}, ^fee_info}] =
               :ets.lookup(Tai.Venues.FeeStore, {:my_exchange, :main_account, :btc_usdt})
    end
  end

  describe "#clear" do
    test "removes the existing items in the ETS table", %{fee_info: fee_info} do
      assert Tai.Venues.FeeStore.upsert(fee_info) == :ok
      assert Tai.Venues.FeeStore.count() == 1

      assert Tai.Venues.FeeStore.clear() == :ok
      assert Tai.Venues.FeeStore.count() == 0
    end
  end

  describe "#all" do
    test "returns a list of all the existing items", %{fee_info: fee_info} do
      assert Tai.Venues.FeeStore.all() == []

      assert Tai.Venues.FeeStore.upsert(fee_info) == :ok

      assert [^fee_info] = Tai.Venues.FeeStore.all()
    end
  end

  describe "#find_by" do
    test "returns the fee info in an ok tuple", %{fee_info: fee_info} do
      assert Tai.Venues.FeeStore.upsert(fee_info) == :ok

      assert {:ok, ^fee_info} =
               Tai.Venues.FeeStore.find_by(
                 exchange_id: :my_exchange,
                 account_id: :main_account,
                 symbol: :btc_usdt
               )
    end

    test "returns an error tuple when not found" do
      assert Tai.Venues.FeeStore.find_by(
               exchange_id: :my_exchange,
               account_id: :main_account,
               symbol: :idontexist
             ) == {:error, :not_found}
    end
  end
end
