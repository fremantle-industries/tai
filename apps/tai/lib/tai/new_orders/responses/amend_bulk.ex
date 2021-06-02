defmodule Tai.NewOrders.Responses.AmendBulk do
  @moduledoc """
  Return from venue adapters when amending orders in bulk
  """

  alias Tai.Orders.Responses.Amend

  @type t :: %__MODULE__{
          orders: [Amend.t()]
        }

  @enforce_keys ~w[orders]a
  defstruct ~w[orders]a
end
