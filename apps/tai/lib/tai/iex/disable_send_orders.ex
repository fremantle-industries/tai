defmodule Tai.IEx.Commands.DisableSendOrders do
  @spec disable :: no_return
  def disable do
    Tai.Commander.disable_send_orders()
    |> IO.puts()

    IEx.dont_display_result()
  end
end
