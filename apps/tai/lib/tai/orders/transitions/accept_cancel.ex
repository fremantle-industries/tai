defmodule Tai.Orders.Transitions.AcceptCancel do
  @moduledoc """
  The cancel request has been accepted by the venue. The result of the canceled
  order is received in the stream.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.Orders.Transition

  @type t :: %__MODULE__{}

  @primary_key false

  embedded_schema do
    field(:last_received_at, :utc_datetime_usec)
    field(:last_venue_timestamp, :utc_datetime_usec)
  end

  def changeset(transition, params) do
    transition
    |> cast(params, [:last_received_at, :last_venue_timestamp])
    |> validate_required([:last_received_at])
  end

  def from, do: ~w[pending_cancel]a

  def attrs(transition) do
    [
      last_received_at: transition.last_received_at,
      last_venue_timestamp: transition.last_venue_timestamp
    ]
  end

  def status(_current) do
    :cancel_accepted
  end
end
