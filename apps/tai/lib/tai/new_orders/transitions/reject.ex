defmodule Tai.NewOrders.Transitions.Reject do
  @moduledoc """
  The order was not accepted by the venue. It most likely didn't pass the
  venue's validation criteria.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.NewOrders.Transition

  @type t :: %__MODULE__{}

  @primary_key false

  embedded_schema do
    field(:venue_order_id, :string)
    field(:last_received_at, :utc_datetime_usec)
    field(:last_venue_timestamp, :utc_datetime_usec)
  end

  def changeset(transition, params) do
    transition
    |> cast(params, [:venue_order_id, :last_received_at, :last_venue_timestamp])
    |> validate_required([:venue_order_id, :last_received_at])
  end

  def from, do: ~w[enqueued]a

  def attrs(transition) do
    [
      venue_order_id: transition.venue_order_id,
      leaves_qty: Decimal.new(0),
      last_received_at: transition.last_received_at,
      last_venue_timestamp: transition.last_venue_timestamp
    ]
  end

  def status(_current) do
    :rejected
  end
end
