defmodule Tai.Exchange do
  def balance(name) do
    name
    |> Tai.Exchanges.Config.adapter
    |> (&(&1.balance())).()
  end

  def quotes(name, symbol) do
    name
    |> Tai.Exchanges.Config.adapter
    |> (&(&1.quotes(symbol))).()
  end

  def buy_limit(name, symbol, price, size) do
    name
    |> Tai.Exchanges.Config.adapter
    |> (&(&1.buy_limit(symbol, price, size))).()
  end
end
