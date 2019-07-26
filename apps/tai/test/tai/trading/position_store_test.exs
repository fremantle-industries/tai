defmodule Tai.Trading.PositionStoreTest do
  use ExUnit.Case
  doctest Tai.Trading.PositionStore

  setup do
    on_exit(fn ->
      Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    :ok
  end

  describe ".add" do
    test "inserts the position keyed by venue id, account id & product symbol" do
      position = build_position()

      assert {:ok, %Tai.Trading.Position{}} = Tai.Trading.PositionStore.add(position)

      assert [{{:my_venue, :my_account, :xbt_usd}, stored_position}] =
               :ets.lookup(Tai.Trading.PositionStore, {:my_venue, :my_account, :xbt_usd})

      assert stored_position == position
    end
  end

  test ".all returns a list of current positions" do
    assert Tai.Trading.PositionStore.all() == []

    {:ok, position} = add_position()

    assert Tai.Trading.PositionStore.all() == [position]
  end

  defp build_position do
    struct(Tai.Trading.Position, %{
      venue_id: :my_venue,
      account_id: :my_account,
      product_symbol: :xbt_usd
    })
  end

  defp add_position do
    build_position()
    |> Tai.Trading.PositionStore.add()
  end
end
