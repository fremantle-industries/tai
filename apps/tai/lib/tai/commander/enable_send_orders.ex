defmodule Tai.Commander.EnableSendOrders do
  @spec execute :: :ok
  def execute do
    Tai.Settings.enable_send_orders!()
  end
end
