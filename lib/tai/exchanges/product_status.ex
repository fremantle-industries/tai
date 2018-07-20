defmodule Tai.Exchanges.ProductStatus do
  @type t ::
          :pre_trading | :trading | :post_trading | :end_of_day | :halt | :auction_match | :break

  def pre_trading(), do: :pre_trading
  def trading(), do: :trading
  def post_trading(), do: :post_trading
  def end_of_day(), do: :end_of_day
  def halt(), do: :halt
  def auction_match(), do: :auction_match
  def break(), do: :break
end
