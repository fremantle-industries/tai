defmodule Tai.Trading.OrderResponse do
  @moduledoc """
  Returned from creating an order
  """

  @typedoc """
  Details of an order executed on an account 
  """
  @type t :: %Tai.Trading.OrderResponse{
          id: String.t(),
          status: atom,
          original_size: Decimal.t(),
          time_in_force: atom,
          executed_size: Decimal.t() | nil
        }

  @enforce_keys [:id, :status, :original_size, :time_in_force, :executed_size]
  defstruct [:id, :status, :original_size, :time_in_force, :executed_size]
end
