defmodule Tai.NewOrders.Transitions.VenueAmendError do
  @moduledoc """
  There was an error amending the order on the venue
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.NewOrders.Transition

  @type t :: %__MODULE__{}

  @primary_key false

  embedded_schema do
    field(:reason, EctoTerm.Embed)
  end

  @fields ~w[reason]a
  def changeset(transition, params) do
    transition
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

  def from, do: ~w[pending_amend]a

  def attrs(_transition) do
    [
      status: :open
    ]
  end
end
