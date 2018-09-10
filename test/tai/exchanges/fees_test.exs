defmodule Tai.Exchanges.FeesTest do
  use ExUnit.Case, async: false
  doctest Tai.Exchanges.Fees

  setup do
    on_exit(fn ->
      Tai.Exchanges.Fees.clear()
    end)

    fee_info = %Tai.Exchanges.FeeInfo{
      exchange_id: :my_exchange,
      account_id: :main_account,
      symbol: :btc_usdt,
      maker: Decimal.new(0.1),
      maker_type: Tai.Exchanges.FeeInfo.percent(),
      taker: Decimal.new(0.1),
      taker_type: Tai.Exchanges.FeeInfo.percent()
    }

    {:ok, %{fee_info: fee_info}}
  end

  describe "#upsert" do
    test "insert the fee info into the ETS table", %{fee_info: fee_info} do
      assert Tai.Exchanges.Fees.upsert(fee_info) == :ok

      assert [{{:my_exchange, :main_account, :btc_usdt}, ^fee_info}] =
               :ets.lookup(Tai.Exchanges.Fees, {:my_exchange, :main_account, :btc_usdt})
    end
  end

  describe "#clear" do
    test "removes the existing items in the ETS table", %{fee_info: fee_info} do
      assert Tai.Exchanges.Fees.upsert(fee_info) == :ok
      assert Tai.Exchanges.Fees.count() == 1

      assert Tai.Exchanges.Fees.clear() == :ok
      assert Tai.Exchanges.Fees.count() == 0
    end
  end

  describe "#all" do
    test "returns a list of all the existing items", %{fee_info: fee_info} do
      assert Tai.Exchanges.Fees.all() == []

      assert Tai.Exchanges.Fees.upsert(fee_info) == :ok

      assert [^fee_info] = Tai.Exchanges.Fees.all()
    end
  end

  describe "#find_by" do
    test "returns the fee info in an ok tuple", %{fee_info: fee_info} do
      assert Tai.Exchanges.Fees.upsert(fee_info) == :ok

      assert {:ok, ^fee_info} =
               Tai.Exchanges.Fees.find_by(
                 exchange_id: :my_exchange,
                 account_id: :main_account,
                 symbol: :btc_usdt
               )
    end

    test "returns an error tuple when not found" do
      assert Tai.Exchanges.Fees.find_by(
               exchange_id: :my_exchange,
               account_id: :main_account,
               symbol: :idontexist
             ) == {:error, :not_found}
    end
  end
end
