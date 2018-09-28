defmodule Tai.Commands.Helper do
  @moduledoc """
  Commands for using `tai` in IEx
  """

  @spec help :: no_return
  defdelegate help, to: Tai.Commands.Info

  @spec balance :: no_return
  defdelegate balance, to: Tai.Commands.Balance

  @spec products :: no_return
  defdelegate products, to: Tai.Commands.Products

  @spec fees :: no_return
  defdelegate fees, to: Tai.Commands.Fees

  @spec markets :: no_return
  defdelegate markets, to: Tai.Commands.Markets

  @spec orders :: no_return
  defdelegate orders, to: Tai.Commands.Orders

  @spec settings :: no_return
  defdelegate settings, to: Tai.Commands.Settings

  @spec disable_send_orders :: no_return
  defdelegate disable_send_orders, to: Tai.Commands.SendOrders, as: :disable

  @spec enable_send_orders :: no_return
  defdelegate enable_send_orders, to: Tai.Commands.SendOrders, as: :enable
end
