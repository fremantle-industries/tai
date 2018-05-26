defmodule Tai.Trading.OrderStatus do
  @moduledoc """
  The normalized states of an order
  """

  def enqueued, do: :enqueued
  def expired, do: :expired
  def pending, do: :pending
  def cancelling, do: :cancelling
  def cancelled, do: :cancelled
  def error, do: :error
end
