defmodule Tai.Commands.SendOrders do
  def disable do
    Tai.Settings.disable_send_orders!()
    render!()
  end

  def enable do
    Tai.Settings.enable_send_orders!()
    render!()
  end

  defp render! do
    Tai.Commands.Settings.settings()
  end
end
