defmodule Tai.Commands.Info do
  @moduledoc """
  Display the available commands and their usage
  """

  def help do
    IO.puts("""
    * balance
    * products
    * markets
    * orders
    * buy_limit exchange_id(:gdax), account_id(:main), symbol(:btc_usd), price(101.12), size(1.2)
    * sell_limit exchange_id(:gdax), account_id(:main), symbol(:btc_usd), price(101.12), size(1.2)
    * order_status exchange_id(:gdax), account_id(:main), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")
    * cancel_order exchange_id(:gdax), account_id(:main), order_id("f1bb2fa3-6218-45be-8691-21b98157f25a")
    * settings
    """)
  end
end
