defmodule Tai.CommandsHelper do
  alias Tai.Fund

  def status do
    IO.puts "#{Fund.balance} USD"
  end
end
