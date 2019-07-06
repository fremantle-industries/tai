defmodule Tai.Commands.Helper do
  @moduledoc """
  Commands for using `tai` in IEx
  """

  @spec help :: no_return
  defdelegate help, to: Tai.Commands.Help

  @spec balance :: no_return
  defdelegate balance, to: Tai.Commands.Balance

  @spec products :: no_return
  defdelegate products, to: Tai.Commands.Products

  @spec fees :: no_return
  defdelegate fees, to: Tai.Commands.Fees

  @spec markets :: no_return
  defdelegate markets, to: Tai.Commands.Markets

  @spec positions :: no_return
  defdelegate positions, to: Tai.Commands.Positions

  @spec orders :: no_return
  defdelegate orders, to: Tai.Commands.Orders

  @spec settings :: no_return
  defdelegate settings, to: Tai.Commands.Settings

  @spec advisors() :: no_return
  defdelegate advisors(), to: Tai.Commands.Advisors, as: :list

  @spec advisors(list) :: no_return
  defdelegate advisors(args), to: Tai.Commands.Advisors, as: :list

  @spec start_advisors() :: no_return
  defdelegate start_advisors(), to: Tai.Commands.Advisors, as: :start

  @spec start_advisors(list) :: no_return
  defdelegate start_advisors(args), to: Tai.Commands.Advisors, as: :start

  @spec stop_advisors() :: no_return
  defdelegate stop_advisors(), to: Tai.Commands.Advisors, as: :stop

  @spec stop_advisors(list) :: no_return
  defdelegate stop_advisors(args), to: Tai.Commands.Advisors, as: :stop

  @spec enable_send_orders :: no_return
  defdelegate enable_send_orders, to: Tai.Commands.SendOrders, as: :enable

  @spec disable_send_orders :: no_return
  defdelegate disable_send_orders, to: Tai.Commands.SendOrders, as: :disable
end
