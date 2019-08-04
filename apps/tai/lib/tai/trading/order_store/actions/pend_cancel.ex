defmodule Tai.Trading.OrderStore.Actions.PendCancel do
  @moduledoc """
  The order is going to be sent to the venue to be canceled
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          updated_at: DateTime.t()
        }

  @enforce_keys ~w(client_id updated_at)a
  defstruct ~w(client_id updated_at)a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.PendCancel do
  def required(_), do: [:open, :partially_filled]

  def attrs(action) do
    %{
      status: :pending_cancel,
      updated_at: action.updated_at
    }
  end
end
