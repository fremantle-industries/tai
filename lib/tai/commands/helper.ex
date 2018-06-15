defmodule Tai.Commands.Helper do
  @moduledoc """
  Commands for using `tai` in IEx
  """

  alias Tai.Commands

  @spec help :: no_return
  defdelegate help, to: Commands.Info

  @spec balance :: no_return
  defdelegate balance, to: Commands.Balance

  @spec markets :: no_return
  defdelegate markets, to: Commands.Markets

  @spec orders :: no_return
  defdelegate orders, to: Commands.Orders

  @spec buy_limit(atom, atom, float, float, atom) :: no_return
  defdelegate buy_limit(account_id, symbol, price, size, time_in_force), to: Commands.Trading

  @spec sell_limit(atom, atom, float, float, atom) :: no_return
  defdelegate sell_limit(account_id, symbol, price, size, time_in_force), to: Commands.Trading

  @spec order_status(atom, String.t()) :: no_return
  defdelegate order_status(account_id, order_id), to: Commands.Trading

  @spec cancel_order(atom, String.t()) :: no_return
  defdelegate cancel_order(account_id, order_id), to: Commands.Trading
end
