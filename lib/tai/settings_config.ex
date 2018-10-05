defmodule Tai.SettingsConfig do
  @moduledoc """
  Module to parse the settings config from the application environment
  """

  def parse do
    %{}
    |> Map.put(
      :send_orders,
      Application.get_env(:tai, :send_orders, false)
    )
    |> Map.put(
      :exchange_boot_handler,
      Application.get_env(:tai, :exchange_boot_handler, Tai.Exchanges.BootHandler)
    )
  end
end
