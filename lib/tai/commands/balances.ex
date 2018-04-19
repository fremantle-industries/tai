defmodule Tai.Commands.Balances do
  alias Tai.Fund

  def balance do
    IO.puts("#{Fund.balance()} USD")
  end
end
