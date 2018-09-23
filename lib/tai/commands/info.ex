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
    * buy_limit exchange_id(:gdax), account_id(:main), symbol(:btc_usd), price(101.12), size(1.2)
    * sell_limit exchange_id(:gdax), account_id(:main), symbol(:btc_usd), price(101.12), size(1.2)
    * settings
    * enable_send_orders
    * disable_send_orders
    """)
  end
end
