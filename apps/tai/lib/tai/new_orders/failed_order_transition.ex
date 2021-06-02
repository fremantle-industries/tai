defmodule Tai.NewOrders.FailedOrderTransition do
  use Ecto.Schema
  import Ecto.Changeset
  alias Tai.NewOrders.Order

  @type t :: %__MODULE__{}

  @timestamps_opts [autogenerate: {Tai.DateTime, :timestamp, []}, type: :utc_datetime_usec]

  schema "failed_order_transitions" do
    belongs_to(:order, Order,
      source: :order_client_id,
      references: :client_id,
      foreign_key: :order_client_id,
      type: Ecto.UUID
    )

    field(:type, :string)
    field(:error, EctoTerm)

    timestamps()
  end

  @doc false
  def changeset(failed_order_transition, attrs) do
    failed_order_transition
    |> cast(attrs, [:order_client_id, :type, :error])
    |> validate_required([:order_client_id, :error])
  end
end
