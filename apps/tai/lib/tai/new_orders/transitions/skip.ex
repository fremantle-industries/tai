defmodule Tai.NewOrders.Transitions.Skip do
  @moduledoc """
  Bypass sending the order to the venue
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

  def from, do: ~w[enqueued]a

  def attrs(_) do
    [
      status: :skipped,
      leaves_qty: Decimal.new(0)
    ]
  end
end
