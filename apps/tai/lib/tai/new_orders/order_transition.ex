defmodule Tai.NewOrders.OrderTransition do
  use Ecto.Schema
  import Ecto.Changeset
  import PolymorphicEmbed, only: [cast_polymorphic_embed: 3]
  alias Tai.NewOrders.{Order, Transitions}

  @type t :: %__MODULE__{}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  @timestamps_opts [autogenerate: {Tai.DateTime, :timestamp, []}, type: :utc_datetime_usec]

  schema "order_transitions" do
    belongs_to(:order, Order,
      source: :order_client_id,
      references: :client_id,
      foreign_key: :order_client_id,
      type: Ecto.UUID
    )

    field(:transition, PolymorphicEmbed,
      types: [
        accept_create: Transitions.AcceptCreate,
        venue_create_error: Transitions.VenueCreateError,
        rescue_create_error: Transitions.RescueCreateError,
        open: Transitions.Open,
        pend_cancel: Transitions.PendCancel,
        accept_cancel: Transitions.AcceptCancel,
        venue_cancel_error: Transitions.VenueCancelError,
        rescue_cancel_error: Transitions.RescueCancelError,
        cancel: Transitions.Cancel,
        pend_amend: Transitions.PendAmend,
        accept_amend: Transitions.AcceptAmend,
        venue_amend_error: Transitions.VenueAmendError,
        rescue_amend_error: Transitions.RescueAmendError,
        amend: Transitions.Amend,
        fill: Transitions.Fill,
        partial_fill: Transitions.PartialFill,
        expire: Transitions.Expire,
        reject: Transitions.Reject,
        skip: Transitions.Skip
      ],
      on_type_not_found: :raise,
      on_replace: :update
    )

    timestamps()
  end

  @doc false
  def changeset(order_transition, attrs) do
    order_transition
    |> cast(attrs, [:order_client_id])
    |> cast_polymorphic_embed(:transition, required: true)
    |> validate_required([:order_client_id])
  end
end
