defmodule Tai.NewOrders.Responses.AmendBulk do
  @moduledoc """
  Return from venue adapters when amending orders in bulk
  """

  alias Tai.NewOrders.Responses.AmendAccepted

  @type t :: %__MODULE__{
          orders: [AmendAccepted.t()]
        }

  @enforce_keys ~w[orders]a
  defstruct ~w[orders]a
end
