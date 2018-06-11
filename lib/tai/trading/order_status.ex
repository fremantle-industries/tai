defmodule Tai.Trading.OrderStatus do
  @moduledoc """
  The states of an order
  """

  def enqueued, do: :enqueued
  def expired, do: :expired
  def pending, do: :pending
  def filled, do: :filled
  def canceling, do: :canceling
  def canceled, do: :canceled
  def error, do: :error
end
