defmodule Tai.ServiceUnavailableError do
  @moduledoc """
  Module which represents errors when the service is responding that they 
  are unavailable

  e.g. HTTP 503
  https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503
  """

  @enforce_keys [:reason]
  defstruct [:reason]
end
