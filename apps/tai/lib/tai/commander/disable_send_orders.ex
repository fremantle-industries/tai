defmodule Tai.Commander.DisableSendOrders do
  @spec execute :: :ok
  def execute do
    Tai.Settings.disable_send_orders!()
  end
end
