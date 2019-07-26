defmodule Tai.Markets.Location do
  @moduledoc """
  The venue a product can be traded
  """

  @type t :: %Tai.Markets.Location{
          venue_id: atom,
          product_symbol: atom
        }

  @enforce_keys [:venue_id, :product_symbol]
  defstruct [:venue_id, :product_symbol]
end
