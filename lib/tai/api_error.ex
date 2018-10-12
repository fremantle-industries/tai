defmodule Tai.ApiError do
  @moduledoc """
  Module which represents errors with credentials e.g. invalid api keys
  """

  @type t :: %Tai.ApiError{}

  @enforce_keys [:reason]
  defstruct [:reason]
end
