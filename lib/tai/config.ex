defmodule Tai.Config do
  @moduledoc """
  Module to parse the config from the application environment
  """

  @enforce_keys [:send_orders, :exchange_boot_handler]
  defstruct [:send_orders, :exchange_boot_handler]

  def parse!(env \\ Application.get_all_env(:tai)) do
    send_orders = !!Keyword.get(env, :send_orders)
    exchange_boot_handler = Keyword.get(env, :exchange_boot_handler, Tai.Exchanges.BootHandler)

    %Tai.Config{
      send_orders: send_orders,
      exchange_boot_handler: exchange_boot_handler
    }
  end
end
