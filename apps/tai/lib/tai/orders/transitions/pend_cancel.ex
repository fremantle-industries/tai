defmodule Tai.Orders.Transitions.PendCancel do
  @moduledoc """
  The order is going to be sent to the venue to be canceled
  """

  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id
        }

  @enforce_keys ~w[client_id]a
  defstruct ~w[client_id]a

  defimpl Tai.Orders.Transition do
    def required(_), do: [:amend_error, :cancel_error, :open, :partially_filled]

    def attrs(_transition) do
      %{
        status: :pending_cancel
      }
    end
  end
end
