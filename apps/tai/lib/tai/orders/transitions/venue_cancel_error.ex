defmodule Tai.Orders.Transitions.VenueCancelError do
  @moduledoc """
  There was an error canceling the order on the venue
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.Orders.Transition

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

  def from, do: ~w[pending_cancel]a

  def attrs(_transition), do: []

  def status(_current) do
    :open
  end
end
