defmodule Tai.Trading.OrderResponses.Created do
  @enforce_keys [:id, :status, :created_at]
  defstruct [:id, :status, :created_at]
end
