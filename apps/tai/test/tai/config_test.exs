defmodule Tai.ConfigTest do
  use ExUnit.Case, async: true
  doctest Tai.Config

  describe ".parse" do
    test "returns a default representation" do
      assert %Tai.Config{} = config = Tai.Config.parse([])
      assert config.adapter_timeout == 10_000
      assert config.advisor_groups == %{}
      assert config.after_boot == nil
      assert config.after_boot_error == nil
      assert config.broadcast_change_set == false
      assert config.send_orders == false
      assert config.system_bus_registry_partitions == System.schedulers_online()
      assert config.venues == %{}
    end

    test "can set adapter_timeout" do
      assert config = Tai.Config.parse(adapter_timeout: 5000)
      assert config.adapter_timeout == 5000
    end

    test "can set advisor_groups" do
      assert config = Tai.Config.parse(advisor_groups: :advisor_groups)
      assert config.advisor_groups == :advisor_groups
    end

    test "can set after_boot" do
      assert config = Tai.Config.parse(after_boot: {AfterBoot, :call})
      assert config.after_boot == {AfterBoot, :call}
    end

    test "can set after_boot_error" do
      assert config = Tai.Config.parse(after_boot_error: {AfterBootError, :call})
      assert config.after_boot_error == {AfterBootError, :call}
    end

    test "can set broadcast_change_set" do
      assert config = Tai.Config.parse(broadcast_change_set: true)
      assert config.broadcast_change_set
    end

    test "can set system_bus_registry_partitions" do
      assert config = Tai.Config.parse(system_bus_registry_partitions: 1)
      assert config.system_bus_registry_partitions == 1
    end

    test "can set send_orders" do
      assert config = Tai.Config.parse(send_orders: true)
      assert config.send_orders == true
    end

    test "can set venues" do
      assert config = Tai.Config.parse(venues: :venues)
      assert config.venues == :venues
    end
  end
end
