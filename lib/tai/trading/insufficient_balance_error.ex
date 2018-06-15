defmodule Tai.Trading.InsufficientBalanceError do
  @moduledoc """
  Returned when there is not enough balance to execute the order
  """

  @type t :: Tai.Trading.InsufficientBalanceError

  @enforce_keys [:reason]
  defstruct [:reason]
end
