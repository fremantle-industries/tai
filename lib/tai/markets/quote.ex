defmodule Tai.Markets.Quote do
  @moduledoc """
  Represents a bid & ask price level row in the order book
  """

  @type price_level :: Tai.Markets.PriceLevel.t()
  @type t :: %Tai.Markets.Quote{
          bid: price_level,
          ask: price_level
        }

  @enforce_keys [:bid, :ask]
  defstruct [:bid, :ask]
end
