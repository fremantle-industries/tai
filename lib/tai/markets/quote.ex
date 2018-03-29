defmodule Tai.Markets.Quote do
  @enforce_keys [:bid, :ask]
  defstruct [:bid, :ask]
end
