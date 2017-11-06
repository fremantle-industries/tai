defmodule Tai.Exchanges.ProductStatus do
  def pre_trading, do: :pre_trading
  def trading, do: :trading
  def post_trading, do: :post_trading
  def end_of_day, do: :end_of_day
  def halt, do: :halt
  def auction_match, do: :auction_match
  def break, do: :break
  def settled, do: :settled
  def unlisted, do: :unlisted
end
