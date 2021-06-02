defmodule Tai.NewOrders.Transitions.PendCancel do
  @moduledoc """
  The order is going to be sent to the venue to be canceled
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.NewOrders.Transition

  @type t :: %__MODULE__{}

  @primary_key false

  embedded_schema do
  end

  def changeset(transition, params) do
    transition
    |> cast(params, [])
  end

  def from, do: ~w[open]a

  def attrs(_transition) do
    [
      status: :pending_cancel
    ]
  end
end
