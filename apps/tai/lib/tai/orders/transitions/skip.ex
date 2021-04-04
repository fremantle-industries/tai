defmodule Tai.Orders.Transitions.Skip do
  @moduledoc """
  Bypass sending the order to the venue
  """

  @type t :: %__MODULE__{client_id: atom}

  @enforce_keys ~w[client_id]a
  defstruct ~w[client_id]a

  defimpl Tai.Orders.Transition do
    def required(_), do: :enqueued
    def attrs(_), do: %{status: :skip, leaves_qty: Decimal.new(0)}
  end
end
