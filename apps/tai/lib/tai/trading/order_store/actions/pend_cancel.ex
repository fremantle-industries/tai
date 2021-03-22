defmodule Tai.Trading.OrderStore.Actions.PendCancel do
  @moduledoc """
  The order is going to be sent to the venue to be canceled
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id
        }

  @enforce_keys ~w[client_id]a
  defstruct ~w[client_id]a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.PendCancel do
  def required(_), do: [:amend_error, :cancel_error, :open, :partially_filled]

  def attrs(_action) do
    %{
      status: :pending_cancel
    }
  end
end
