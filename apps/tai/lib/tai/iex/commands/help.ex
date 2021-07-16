defmodule Tai.IEx.Commands.Help do
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
    * orders_count
    * order :order_client_id
    * get_order_by_client_id :order_client_id
    * get_orders_by_client_ids :order_client_ids
    * order_transitions :order_client_id
    * order_transitions_count :order_client_id
    * failed_order_transitions :order_client_id
    * failed_order_transitions_count :order_client_id
    * delete_all_orders
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
