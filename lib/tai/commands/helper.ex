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

  @spec positions :: no_return
  defdelegate positions, to: Tai.Commands.Positions

  @spec orders :: no_return
  defdelegate orders, to: Tai.Commands.Orders

  @spec settings :: no_return
  defdelegate settings, to: Tai.Commands.Settings

  @spec advisor_groups :: no_return
  defdelegate advisor_groups, to: Tai.Commands.AdvisorGroups

  @spec advisor_groups(config) :: no_return
  defdelegate advisor_groups(config), to: Tai.Commands.AdvisorGroups

  @spec start_advisor_group(atom) :: no_return
  defdelegate start_advisor_group(group_id),
    to: Tai.Commands.AdvisorGroups,
    as: :start

  @spec stop_advisor_group(atom) :: no_return
  defdelegate stop_advisor_group(group_id),
    to: Tai.Commands.AdvisorGroups,
    as: :stop

  @spec advisors :: no_return
  defdelegate advisors, to: Tai.Commands.Advisors

  @spec advisors(config) :: no_return
  defdelegate advisors(config), to: Tai.Commands.Advisors

  @spec start_advisors :: no_return
  defdelegate start_advisors, to: Tai.Commands.Advisors, as: :start

  @spec stop_advisors :: no_return
  defdelegate stop_advisors, to: Tai.Commands.Advisors, as: :stop

  @spec start_advisor(atom, atom) :: no_return
  defdelegate start_advisor(group_id, advisor_id),
    to: Tai.Commands.Advisor,
    as: :start_advisor

  @spec start_advisor(atom, atom, config) :: no_return
  defdelegate start_advisor(group_id, advisor_id, config),
    to: Tai.Commands.Advisor,
    as: :start_advisor

  @spec advisor(atom, atom) :: no_return
  defdelegate advisor(group_id, advisor_id), to: Tai.Commands.Advisor

  @spec advisor(atom, atom, config) :: no_return
  defdelegate advisor(group_id, advisor_id, config), to: Tai.Commands.Advisor

  @spec stop_advisor(atom, atom) :: no_return
  defdelegate stop_advisor(group_id, advisor_id),
    to: Tai.Commands.Advisor,
    as: :stop_advisor

  @spec stop_advisor(atom, atom, config) :: no_return
  defdelegate stop_advisor(group_id, advisor_id, config),
    to: Tai.Commands.Advisor,
    as: :stop_advisor

  @spec enable_send_orders :: no_return
  defdelegate enable_send_orders, to: Tai.Commands.SendOrders, as: :enable

  @spec disable_send_orders :: no_return
  defdelegate disable_send_orders, to: Tai.Commands.SendOrders, as: :disable
end
