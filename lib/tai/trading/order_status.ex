defmodule Tai.Trading.OrderStatus do
  def enqueued, do: :enqueued
  def pending, do: :pending
  def cancelling, do: :cancelling
  def cancelled, do: :cancelled
  def error, do: :error
end
