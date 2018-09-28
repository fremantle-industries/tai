defmodule Tai.Trading.TimeInForce do
  @moduledoc """
  Order lifetime policies
  """

  def good_till_cancel, do: :gtc
  def fill_or_kill, do: :fok
  def immediate_or_cancel, do: :ioc
end
