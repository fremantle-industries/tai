defmodule Tai.Exchange do
  alias Tai.Exchanges.Config

  def balance(name) do
    name
    |> Config.adapter
    |> (&(&1.balance())).()
  end

  def quotes(name, symbol) do
    name
    |> Config.adapter
    |> (&(&1.quotes(symbol))).()
  end

  def buy_limit(name, symbol, price, size) do
    name
    |> Config.adapter
    |> (&(&1.buy_limit(symbol, price, size))).()
  end

  def order_status(name, order_id) do
    name
    |> Config.adapter
    |> (&(&1.order_status(order_id))).()
  end
end
