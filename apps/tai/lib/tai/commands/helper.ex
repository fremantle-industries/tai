defmodule Tai.Commands.Helper do
  @moduledoc """
  Commands for using `tai` in IEx
  """

  @deprecated "Use Tai.CommandsHelper.help/0 instead."
  @spec help :: no_return
  defdelegate help, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.balance/0 instead."
  @spec balance :: no_return
  defdelegate balance, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.products/0 instead."
  @spec products :: no_return
  defdelegate products, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.fees/0 instead."
  @spec fees :: no_return
  defdelegate fees, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.markets/0 instead."
  @spec markets :: no_return
  defdelegate markets, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.positions/0 instead."
  @spec positions :: no_return
  defdelegate positions, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.orders/0 instead."
  @spec orders :: no_return
  defdelegate orders, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.settings/0 instead."
  @spec settings :: no_return
  defdelegate settings, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.advisors/0 instead."
  @spec advisors() :: no_return
  defdelegate advisors(), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.advisors/1 instead."
  @spec advisors(list) :: no_return
  defdelegate advisors(args), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.start_advisors/0 instead."
  @spec start_advisors() :: no_return
  defdelegate start_advisors(), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.start_advisors/1 instead."
  @spec start_advisors(list) :: no_return
  defdelegate start_advisors(args), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.stop_advisors/0 instead."
  @spec stop_advisors() :: no_return
  defdelegate stop_advisors(), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.stop_advisors/1 instead."
  @spec stop_advisors(list) :: no_return
  defdelegate stop_advisors(args), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.enable_send_orders/0 instead."
  @spec enable_send_orders :: no_return
  defdelegate enable_send_orders, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.disable_send_orders/0 instead."
  @spec disable_send_orders :: no_return
  defdelegate disable_send_orders, to: Tai.CommandsHelper
end
