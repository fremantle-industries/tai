defmodule Tai.ConfigTest do
  use ExUnit.Case, async: false
  doctest Tai.Config

  describe ".parse" do
    test "returns a default representation" do
      assert Tai.Config.parse([]) == %Tai.Config{
               send_orders: false,
               exchange_boot_handler: Tai.Exchanges.BootHandler,
               venues: %{},
               advisor_groups: %{}
             }
    end

    test "can set send_orders" do
      assert config = Tai.Config.parse(send_orders: true)
      assert config.send_orders == true
    end

    test "can set exchange_boot_handler" do
      assert config = Tai.Config.parse(exchange_boot_handler: MyBootHandler)
      assert config.exchange_boot_handler == MyBootHandler
    end

    test "can set venues" do
      assert config = Tai.Config.parse(venues: :venues)
      assert config.venues == :venues
    end

    test "can set advisor_groups" do
      assert config = Tai.Config.parse(advisor_groups: :advisor_groups)
      assert config.advisor_groups == :advisor_groups
    end
  end
end
