defmodule Tai.Commands.Helper.SettingsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  test "settings displays the current values" do
    assert capture_io(&Tai.Commands.Helper.settings/0) == """
           +-----------------------+------------------------------------+
           |                  Name |                              Value |
           +-----------------------+------------------------------------+
           | exchange_boot_handler | Elixir.Support.ExchangeBootHandler |
           |           send_orders |                               true |
           +-----------------------+------------------------------------+\n
           """
  end
end
