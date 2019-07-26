defmodule Tai.Trading.OrderStore.Actions.CreateError do
  @moduledoc """
  There was an error creating the order on the venue.
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          reason: term,
          last_received_at: DateTime.t()
        }

  @enforce_keys ~w(client_id reason last_received_at)a
  defstruct ~w(client_id reason last_received_at)a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.CreateError do
  def required(_), do: :enqueued

  def attrs(action) do
    %{
      status: :create_error,
      leaves_qty: Decimal.new(0),
      error_reason: action.reason,
      last_received_at: action.last_received_at
    }
  end
end
