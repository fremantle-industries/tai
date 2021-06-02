defmodule Tai.NewOrders.Transitions.Cancel do
  @moduledoc """
  The order was successfully canceled on the venue
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.NewOrders.Transition

  @type t :: %__MODULE__{}

  @primary_key false

  embedded_schema do
    field(:last_received_at, :utc_datetime_usec)
    field(:last_venue_timestamp, :utc_datetime_usec)
  end

  def changeset(transition, params) do
    transition
    |> cast(params, [:last_received_at, :last_venue_timestamp])
    |> validate_required(:last_received_at)
  end

  def from, do: ~w[create_accepted open pending_cancel cancel_accepted]a

  def attrs(transition) do
    [
      status: :canceled,
      leaves_qty: Decimal.new(0),
      last_received_at: transition.last_received_at,
      last_venue_timestamp: transition.last_venue_timestamp
    ]
  end
end
