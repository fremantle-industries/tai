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
    * venues [where: [...], order: [...]]
    * start_venue :venue_id
    * stop_venue :venue_id
    * advisors [where: [...], order: [...]]
    * start_advisors [where: [...]]
    * stop_advisors [where: [...]]
    * settings
    * enable_send_orders
    * disable_send_orders
    """)

    IEx.dont_display_result()
  end
end
