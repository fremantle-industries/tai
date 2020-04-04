defmodule Tai.IEx.Commands.EnableSendOrders do
  @spec enable :: no_return
  def enable do
    Tai.Commander.enable_send_orders()
    |> IO.puts()

    IEx.dont_display_result()
  end
end
