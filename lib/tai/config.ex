defmodule Tai.Config do
  @moduledoc """
  Module to parse the config from the application environment
  """

  @type t :: %Tai.Config{
          send_orders: Boolean.t(),
          exchange_boot_handler: atom,
          venues: map
        }

  @enforce_keys [:send_orders, :exchange_boot_handler, :venues]
  defstruct [:send_orders, :exchange_boot_handler, :venues]

  def parse(env \\ Application.get_all_env(:tai)) do
    send_orders = !!Keyword.get(env, :send_orders)
    exchange_boot_handler = Keyword.get(env, :exchange_boot_handler, Tai.Exchanges.BootHandler)
    venues = Keyword.get(env, :venues, %{})

    %Tai.Config{
      send_orders: send_orders,
      exchange_boot_handler: exchange_boot_handler,
      venues: venues
    }
  end
end
