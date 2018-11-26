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
    * advisor_groups
    * advisors
    * settings
    * start_advisors
    * start_advisor_group :group_id
    * start_advisor :group_id, :advisor_id
    * stop_advisors
    * stop_advisor_group :group_id
    * stop_advisor :group_id, :advisor_id
    * enable_send_orders
    * disable_send_orders
    """)

    IEx.dont_display_result()
  end
end
