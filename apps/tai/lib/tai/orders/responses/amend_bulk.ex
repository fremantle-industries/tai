defmodule Tai.Orders.Responses.AmendBulk do
  @moduledoc """
  Return from venue adapters when amending orders in bulk
  """

  alias __MODULE__
  alias Tai.Orders.Responses.Amend

  @type t :: %AmendBulk{
          orders: [Amend.t()]
        }

  @enforce_keys ~w[orders]a
  defstruct ~w[orders]a
end
