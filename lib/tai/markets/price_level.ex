defmodule Tai.Markets.PriceLevel do
  @enforce_keys [:price, :size]
  defstruct [:price, :size, :processed_at, :server_changed_at]
end
