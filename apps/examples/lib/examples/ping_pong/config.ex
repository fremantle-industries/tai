defmodule Examples.PingPong.Config do
  alias __MODULE__

  @type product :: Tai.Venues.Product.t()
  @type fee :: Tai.Venues.FeeInfo.t()
  @type t :: %Config{
          product: product,
          fee: fee,
          max_qty: Decimal.t()
        }

  @enforce_keys ~w(product fee max_qty)a
  defstruct ~w(product fee max_qty)a
end
