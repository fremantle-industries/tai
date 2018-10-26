defmodule Tai.SettingsTest do
  use ExUnit.Case, async: false

  test ".from_config returns a settings struct with send_orders from the config" do
    config = Tai.Config.parse(send_orders: true)

    assert Tai.Settings.from_config(config) == %Tai.Settings{
             send_orders: true
           }
  end

  test ".start_link stores the settings in an ETS table" do
    config = Tai.Config.parse(send_orders: true)
    settings = Tai.Settings.from_config(config)
    start_supervised!({Tai.Settings, settings})

    assert :ets.lookup(Tai.Settings, :send_orders) == [{:send_orders, true}]
  end

  test ".send_orders? returns the value from the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    settings = Tai.Settings.from_config(config)
    start_supervised!({Tai.Settings, settings})

    assert Tai.Settings.send_orders?() == true
  end

  test ".enable_send_orders! updates the value in the ETS table" do
    config = Tai.Config.parse(send_orders: false)
    settings = Tai.Settings.from_config(config)
    start_supervised!({Tai.Settings, settings})

    :ok = Tai.Settings.enable_send_orders!()

    assert :ets.lookup(Tai.Settings, :send_orders) == [{:send_orders, true}]
  end

  test ".disable_send_orders! updates the value in the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    settings = Tai.Settings.from_config(config)
    start_supervised!({Tai.Settings, settings})

    :ok = Tai.Settings.disable_send_orders!()

    assert :ets.lookup(Tai.Settings, :send_orders) == [{:send_orders, false}]
  end

  test ".all returns a struct with the values from the ETS table" do
    config = Tai.Config.parse(send_orders: true)
    settings = Tai.Settings.from_config(config)
    start_supervised!({Tai.Settings, settings})

    settings = Tai.Settings.all()

    assert settings.send_orders == true
  end
end
