defmodule Tai.Trading.InsufficientBalanceError do
  @moduledoc """
  Returned when there is not enough balance to execute the order
  """

  @enforce_keys [:reason]
  defstruct [:reason]
end
