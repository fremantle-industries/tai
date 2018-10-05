defmodule Tai.TimeoutError do
  @moduledoc """
  Module which represents a timeout error
  """

  @type t :: Tai.TimeoutError

  defstruct reason: "network request timed out"
end
