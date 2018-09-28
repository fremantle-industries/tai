defmodule Tai.Commands.Info do
  @moduledoc """
  Display the available commands and their usage
  """

  def help do
    IO.puts("""
    * balance
    * products
    * fees
    * markets
    * orders
    * settings
    * enable_send_orders
    * disable_send_orders
    """)
  end
end
