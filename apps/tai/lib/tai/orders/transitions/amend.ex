defmodule Tai.Orders.Transitions.Amend do
  @moduledoc """
  The order was successfully amended on the venue.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.Orders.Transition

  @type t :: %__MODULE__{}

  @primary_key false

  embedded_schema do
    field(:price, :decimal)
    field(:leaves_qty, :decimal)
    field(:last_received_at, :utc_datetime_usec)
    field(:last_venue_timestamp, :utc_datetime_usec)
  end

  def changeset(transition, params) do
    transition
    |> cast(params, [:price, :leaves_qty, :last_received_at, :last_venue_timestamp])
    |> validate_required([:price, :leaves_qty, :last_received_at])
  end

  def from, do: ~w[pending_amend amend_accepted]a

  def attrs(transition) do
    [
      price: transition.price,
      leaves_qty: transition.leaves_qty,
      last_received_at: transition.last_received_at,
      last_venue_timestamp: transition.last_venue_timestamp
    ]
  end

  def status(_current) do
    :open
  end
end
