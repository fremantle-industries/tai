defmodule Tai.NewOrders.Transitions.Open do
  @moduledoc """
  The order has been created on the venue and is passively sitting in the
  order book waiting to be filled, canceled or amended
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.NewOrders.Transition

  @type t :: %__MODULE__{}

  @primary_key false

  embedded_schema do
    field(:venue_order_id, :string)
    field(:cumulative_qty, :decimal)
    field(:leaves_qty, :decimal)
    field(:last_received_at, :utc_datetime_usec)
    field(:last_venue_timestamp, :utc_datetime_usec)
  end

  def changeset(transition, params) do
    transition
    |> cast(params, [
      :venue_order_id,
      :cumulative_qty,
      :leaves_qty,
      :last_received_at,
      :last_venue_timestamp
    ])
    |> validate_required([:venue_order_id, :cumulative_qty, :leaves_qty, :last_received_at])
  end

  def from, do: ~w[enqueued create_accepted]a

  def attrs(transition) do
    qty = Decimal.add(transition.cumulative_qty, transition.leaves_qty)

    [
      venue_order_id: transition.venue_order_id,
      cumulative_qty: transition.cumulative_qty,
      leaves_qty: transition.leaves_qty,
      qty: qty,
      last_received_at: transition.last_received_at,
      last_venue_timestamp: transition.last_venue_timestamp
    ]
  end

  def status(_current) do
    :open
  end
end
