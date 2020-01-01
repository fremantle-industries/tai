defmodule Tai.Commands.Balance do
  @deprecated "Use Tai.Commands.Accounts.accounts/0 instead."
  @spec balance :: no_return
  def balance do
    Tai.Commands.Accounts.accounts()
  end
end
