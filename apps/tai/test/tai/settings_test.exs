defmodule Tai.SettingsTest do
  use ExUnit.Case, async: false

  test ".start_link stores the settings in an ETS table" do
    config = Tai.Config.parse(send_orders: true)
    start_supervised!({Tai.Settings, config})

    assert :ets.lookup(Tai.Settings, :send_orders) == [{:send_orders, true}]
  end

  test ".send_orders? returns the value from the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    start_supervised!({Tai.Settings, config})

    assert Tai.Settings.send_orders?() == true
  end

  test ".enable_send_orders! updates the value in the ETS table" do
    config = Tai.Config.parse(send_orders: false)
    start_supervised!({Tai.Settings, config})

    :ok = Tai.Settings.enable_send_orders!()

    assert :ets.lookup(Tai.Settings, :send_orders) == [{:send_orders, true}]
  end

  test ".disable_send_orders! updates the value in the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    start_supervised!({Tai.Settings, config})

    :ok = Tai.Settings.disable_send_orders!()

    assert :ets.lookup(Tai.Settings, :send_orders) == [{:send_orders, false}]
  end

  test ".all returns a struct with the values from the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    start_supervised!({Tai.Settings, config})

    settings = Tai.Settings.all()

    assert settings.send_orders == true
  end
end
