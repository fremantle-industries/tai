defmodule Tai.SettingsTest do
  use ExUnit.Case, async: true

  describe ".from_config" do
    test "returns a settings struct with send_orders from the config" do
      config = Tai.Config.parse!(send_orders: true)

      assert Tai.Settings.from_config(config) == %Tai.Settings{
               send_orders: true
             }
    end
  end
end
