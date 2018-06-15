defmodule Tai.TimeoutError do
  @moduledoc """
  Module which represents a timeout error
  """

  @type t :: Tai.TimeoutError

  @enforce_keys [:reason]
  defstruct [:reason]
end
