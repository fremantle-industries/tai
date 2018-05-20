defmodule Tai.TimeoutError do
  @moduledoc """
  Module which represents a timeout error
  """

  @enforce_keys [:message]
  defstruct [:message]
end
