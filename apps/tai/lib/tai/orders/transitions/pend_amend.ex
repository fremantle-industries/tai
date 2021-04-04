defmodule Tai.Orders.Transitions.PendAmend do
  @moduledoc """
  The order is going to be sent to the venue to be amended
  """

  alias __MODULE__

  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %PendAmend{client_id: client_id}

  @enforce_keys ~w[client_id]a
  defstruct ~w[client_id]a

  defimpl Tai.Orders.Transition do
    def required(_), do: [:open, :partially_filled, :amend_error]

    def attrs(_transition) do
      %{
        status: :pending_amend,
        error_reason: nil
      }
    end
  end
end
