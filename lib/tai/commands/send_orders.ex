defmodule Tai.Commands.SendOrders do
  @spec disable :: no_return
  def disable do
    Tai.Settings.disable_send_orders!()
    render!()
  end

  @spec enable :: no_return
  def enable do
    Tai.Settings.enable_send_orders!()
    render!()
  end

  @spec render! :: no_return
  defp render! do
    Tai.Commands.Settings.settings()
  end
end
