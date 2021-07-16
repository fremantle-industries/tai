defmodule Tai.Orders.Transitions.Skip do
  @moduledoc """
  Bypass sending the order to the venue
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.Orders.Transition

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
      leaves_qty: Decimal.new(0)
    ]
  end

  def status(_current) do
    :skipped
  end
end
