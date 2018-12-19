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
          cumulative_qty: Decimal.t() | nil
        }

  @enforce_keys [:id, :status, :original_size, :time_in_force, :cumulative_qty]
  defstruct [:id, :status, :original_size, :time_in_force, :cumulative_qty]
end
