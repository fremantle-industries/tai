defmodule Tai.TimeoutError do
  @moduledoc """
  Module which represents a timeout error
  """

  @type t :: %Tai.TimeoutError{reason: String.t()}

  defstruct reason: "network request timed out"
end
