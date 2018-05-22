defmodule Tai.Trading.NotEnoughError do
  @moduledoc """
  Returned when there is not enough of a balance to execute the order
  """

  @enforce_keys [:reason]
  defstruct [:reason]
end
