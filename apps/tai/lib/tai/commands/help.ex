defmodule Tai.Commands.Help do
  @moduledoc """
  Display the available commands and their usage
  """

  def help do
    IO.puts("""
    * accounts
    * products
    * fees
    * markets
    * orders
    * settings
    * advisors [where: [...], order: [...]]
    * start_advisors [where: [...]]
    * stop_advisors [where: [...]]
    * enable_send_orders
    * disable_send_orders
    """)

    IEx.dont_display_result()
  end
end
