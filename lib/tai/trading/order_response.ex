defmodule Tai.Trading.OrderResponse do
  @moduledoc """
  Returned from creating an order
  """

  @enforce_keys [:id]
  defstruct [:id]
end
