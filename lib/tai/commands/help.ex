defmodule Tai.Commands.Help do
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
    * advisors
    * settings
    * start_advisor_groups
    * start_advisor_group :group_id
    * stop_advisor_groups
    * stop_advisor_group :group_id
    * enable_send_orders
    * disable_send_orders
    """)
  end
end
