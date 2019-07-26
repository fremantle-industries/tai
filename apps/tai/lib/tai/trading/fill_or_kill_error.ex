defmodule Tai.Trading.FillOrKillError do
  @moduledoc """
  Returned when there is a problem creating fill or kill orders
  """

  @enforce_keys [:reason]
  defstruct [:reason]
end
