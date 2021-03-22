defmodule Tai.Trading.OrderStore.Actions.Amend do
  @moduledoc """
  The order was successfully amended on the venue
  """

  @type client_id :: Tai.Trading.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          price: Decimal.t(),
          leaves_qty: Decimal.t(),
          last_received_at: integer,
          last_venue_timestamp: DateTime.t()
        }

  @enforce_keys ~w[client_id price leaves_qty last_received_at last_venue_timestamp]a
  defstruct ~w[client_id price leaves_qty last_received_at last_venue_timestamp]a
end

defimpl Tai.Trading.OrderStore.Action, for: Tai.Trading.OrderStore.Actions.Amend do
  def required(_), do: [:partially_filled, :pending_amend]

  def attrs(action) do
    {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(action.last_received_at)

    %{
      status: :open,
      price: action.price,
      leaves_qty: action.leaves_qty,
      last_received_at: last_received_at,
      last_venue_timestamp: action.last_venue_timestamp
    }
  end
end
