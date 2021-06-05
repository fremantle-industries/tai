defmodule Tai.NewOrders.Transitions.RescueCreateError do
  @moduledoc """
  While sending the create order request to the venue there was an uncaught
  error from the adapter, or an error processing it's response.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Tai.NewOrders.Transition

  @type t :: %__MODULE__{}

  @primary_key false

  embedded_schema do
    field(:error, EctoTerm.Embed)
    field(:stacktrace, EctoTerm.Embed)
  end

  @fields ~w[error stacktrace]a
  def changeset(transition, params) do
    transition
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

  def from, do: ~w[enqueued]a

  def attrs(_transition) do
    [
      leaves_qty: Decimal.new(0)
    ]
  end

  def status(_current) do
    :create_error
  end
end
