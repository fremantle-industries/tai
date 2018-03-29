defmodule Tai.Markets.Quote do
  alias Tai.Markets.Quote

  @enforce_keys [:bid, :ask]
  defstruct [:bid, :ask]

  @typedoc """
  Represents a bid & ask price level row in the order book
  """
  @type t :: Quote
end
