defmodule Tai.SettingsTest do
  # use ExUnit.Case, async: false
  use Tai.TestSupport.DataCase, async: false

  @test_id __MODULE__

  test ".start_link stores the settings in an ETS table" do
    config = Tai.Config.parse(send_orders: true)
    start_supervised!({Tai.Settings, [config: config, id: @test_id]})

    name = Tai.Settings.process_name(@test_id)
    assert :ets.lookup(name, :send_orders) == [{:send_orders, true}]
  end

  test ".send_orders? returns the value from the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    start_supervised!({Tai.Settings, [config: config, id: @test_id]})

    assert Tai.Settings.send_orders?(@test_id) == true
  end

  test ".enable_send_orders! updates the value in the ETS table" do
    config = Tai.Config.parse(send_orders: false)
    start_supervised!({Tai.Settings, [config: config, id: @test_id]})

    :ok = Tai.Settings.enable_send_orders!(@test_id)

    name = Tai.Settings.process_name(@test_id)
    assert :ets.lookup(name, :send_orders) == [{:send_orders, true}]
  end

  test ".disable_send_orders! updates the value in the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    start_supervised!({Tai.Settings, [config: config, id: @test_id]})

    :ok = Tai.Settings.disable_send_orders!(@test_id)

    name = Tai.Settings.process_name(@test_id)
    assert :ets.lookup(name, :send_orders) == [{:send_orders, false}]
  end

  test ".all returns a struct with the values from the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    start_supervised!({Tai.Settings, [config: config, id: @test_id]})

    settings = Tai.Settings.all(@test_id)

    assert settings.send_orders == true
  end
end
