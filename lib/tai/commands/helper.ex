defmodule Tai.Commands.Helper do
  @moduledoc """
  Commands for using `tai` in IEx
  """

  @type config :: Tai.Config.t()

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

  @spec orders :: no_return
  defdelegate orders, to: Tai.Commands.Orders

  @spec advisor_groups :: no_return
  defdelegate advisor_groups, to: Tai.Commands.AdvisorGroups

  @spec advisors :: no_return
  defdelegate advisors, to: Tai.Commands.Advisors

  @spec settings :: no_return
  defdelegate settings, to: Tai.Commands.Settings

  @spec start_advisors :: no_return
  defdelegate start_advisors, to: Tai.Commands.Advisors, as: :start

  @spec start_advisor_group(group_id :: atom) :: no_return
  defdelegate start_advisor_group(group_id),
    to: Tai.Commands.AdvisorGroups,
    as: :start

  @spec start_advisor(group_id :: atom, advisor_id :: atom) :: no_return
  defdelegate start_advisor(group_id, advisor_id),
    to: Tai.Commands.Advisors,
    as: :start_advisor

  @spec stop_advisors :: no_return
  defdelegate stop_advisors, to: Tai.Commands.Advisors, as: :stop

  @spec stop_advisor_group(group_id :: atom) :: no_return
  defdelegate stop_advisor_group(group_id),
    to: Tai.Commands.AdvisorGroups,
    as: :stop

  @spec stop_advisor(group_id :: atom, advisor_id :: atom) :: no_return
  defdelegate stop_advisor(group_id, advisor_id),
    to: Tai.Commands.Advisors,
    as: :stop_advisor

  @spec enable_send_orders :: no_return
  defdelegate enable_send_orders, to: Tai.Commands.SendOrders, as: :enable

  @spec disable_send_orders :: no_return
  defdelegate disable_send_orders, to: Tai.Commands.SendOrders, as: :disable
end
