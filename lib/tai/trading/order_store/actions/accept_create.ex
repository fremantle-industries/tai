defmodule Tai.Trading.OrderStore.Actions.AcceptCreate do
  @moduledoc """
  The create request has been accepted by the venue. The result of the
  created order has been received in the connection stream.
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type venue_order_id :: Tai.Trading.Order.venue_order_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          venue_order_id: venue_order_id,
          last_received_at: DateTime.t(),
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w(client_id venue_order_id last_received_at)a
  defstruct ~w(client_id venue_order_id last_received_at last_venue_timestamp)a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.AcceptCreate do
  def required(_), do: :enqueued

  def attrs(action) do
    %{
      status: :create_accepted,
      venue_order_id: action.venue_order_id,
      last_received_at: action.last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    }
  end
end
