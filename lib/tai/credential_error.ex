defmodule Tai.CredentialError do
  @moduledoc """
  Module which represents errors with credentials e.g. invalid api keys
  """

  @type t :: %Tai.CredentialError{reason: String.t()}

  @enforce_keys [:reason]
  defstruct [:reason]
end
