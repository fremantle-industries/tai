defmodule Tai.Commands.Helper do
  @moduledoc """
  Commands for using `tai` in IEx
  """

  @deprecated "Use Tai.CommandsHelper.help/0 instead."
  defdelegate help, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.balance/0 instead."
  defdelegate balance, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.products/0 instead."
  defdelegate products, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.fees/0 instead."
  defdelegate fees, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.markets/0 instead."
  defdelegate markets, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.positions/0 instead."
  defdelegate positions, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.orders/0 instead."
  defdelegate orders, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.settings/0 instead."
  defdelegate settings, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.advisors/0 instead."
  defdelegate advisors(), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.advisors/1 instead."
  defdelegate advisors(args), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.start_advisors/0 instead."
  defdelegate start_advisors(), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.start_advisors/1 instead."
  defdelegate start_advisors(args), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.stop_advisors/0 instead."
  defdelegate stop_advisors(), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.stop_advisors/1 instead."
  defdelegate stop_advisors(args), to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.enable_send_orders/0 instead."
  defdelegate enable_send_orders, to: Tai.CommandsHelper

  @deprecated "Use Tai.CommandsHelper.disable_send_orders/0 instead."
  defdelegate disable_send_orders, to: Tai.CommandsHelper
end
