defmodule Tai.VenueAdapters.Bitmex.OrderStatusTest do
  use ExUnit.Case, async: true
  alias Tai.VenueAdapters.Bitmex.OrderStatus

  describe "New, PartiallyFilled & Filled" do
    test "maps to tai status" do
      assert OrderStatus.from_venue_status("New", :ignore) == :open
      assert OrderStatus.from_venue_status("PartiallyFilled", :ignore) == :open
      assert OrderStatus.from_venue_status("Filled", :ignore) == :filled
    end
  end

  describe "Canceled" do
    test "ioc & fok are expired in tai" do
      assert OrderStatus.from_venue_status(
               "Canceled",
               struct(Tai.Orders.Order, time_in_force: :ioc)
             ) == :expired

      assert OrderStatus.from_venue_status(
               "Canceled",
               struct(Tai.Orders.Order, time_in_force: :fok)
             ) == :expired
    end

    test "gtc post only is rejected in tai" do
      assert OrderStatus.from_venue_status(
               "Canceled",
               struct(Tai.Orders.Order, time_in_force: :gtc, post_only: true)
             ) == :rejected

      assert OrderStatus.from_venue_status(
               "Canceled",
               struct(Tai.Orders.Order, time_in_force: :gtc, post_only: false)
             ) == :canceled
    end

    test "others are also canceled in tai" do
      assert OrderStatus.from_venue_status(
               "Canceled",
               struct(Tai.Orders.Order)
             ) == :canceled
    end
  end
end
