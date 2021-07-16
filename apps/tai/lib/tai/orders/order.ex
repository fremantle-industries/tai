defmodule Tai.Orders.Order do
  use Ecto.Schema
  import Ecto.Changeset

  @type client_id :: Ecto.UUID.t()
  @type venue_order_id :: String.t()
  @type status :: atom
  @type side :: atom
  @type type :: atom
  @type time_in_force :: atom
  @type t :: %__MODULE__{}

  @product_type ~w[spot future swap option]a
  @status ~w[
    enqueued
    create_accepted
    create_error
    open
    filled
    pending_cancel
    cancel_accepted
    canceled
    pending_amend
    amend_accepted
    expired
    rejected
    skipped
  ]a
  @time_in_force ~w[gtc fok ioc]a
  @side ~w[buy sell]a
  @order_type ~w[limit]a

  @primary_key {:client_id, Ecto.UUID, autogenerate: true}
  @timestamps_opts [autogenerate: {Tai.DateTime, :timestamp, []}, type: :utc_datetime_usec]

  schema "orders" do
    field(:close, :boolean)
    field(:credential, :string)
    field(:cumulative_qty, :decimal)
    field(:last_received_at, :utc_datetime)
    field(:last_venue_timestamp, :utc_datetime)
    field(:leaves_qty, :decimal)
    field(:post_only, :boolean)
    field(:price, :decimal)
    field(:product_symbol, :string)
    field(:product_type, Ecto.Enum, values: @product_type)
    field(:qty, :decimal)
    field(:side, Ecto.Enum, values: @side)
    field(:status, Ecto.Enum, values: @status)
    field(:time_in_force, Ecto.Enum, values: @time_in_force)
    field(:type, Ecto.Enum, values: @order_type)
    field(:venue, :string)
    field(:venue_order_id, :string)
    field(:venue_product_symbol, :string)

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [
      :close,
      :credential,
      :cumulative_qty,
      :last_received_at,
      :last_venue_timestamp,
      :leaves_qty,
      :post_only,
      :price,
      :product_symbol,
      :product_type,
      :qty,
      :side,
      :status,
      :time_in_force,
      :type,
      :venue,
      :venue_order_id,
      :venue_product_symbol
    ])
    |> validate_required([
      :credential,
      :cumulative_qty,
      :leaves_qty,
      :post_only,
      :price,
      :product_symbol,
      :product_type,
      :qty,
      :side,
      :status,
      :time_in_force,
      :type,
      :venue,
      :venue_product_symbol
    ])
  end
end
