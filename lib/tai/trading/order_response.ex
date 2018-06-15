defmodule Tai.Trading.OrderResponse do
  @moduledoc """
  Returned from creating an order
  """

  @typedoc """
  Details of an order executed on an account 
  """
  @type t :: Tai.Trading.OrderResponse

  @enforce_keys [:id, :status, :original_size, :time_in_force, :executed_size]
  defstruct [:id, :status, :original_size, :time_in_force, :executed_size]
end
