defmodule Tai.NewOrders.OrderRepo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add(:client_id, :uuid, null: false, primary_key: true)
      add(:close, :boolean)
      add(:credential, :string, null: false)
      add(:cumulative_qty, :decimal, null: false)
      add(:last_received_at, :utc_datetime)
      add(:last_venue_timestamp, :utc_datetime)
      add(:leaves_qty, :decimal, null: false)
      add(:post_only, :boolean, null: false)
      add(:price, :decimal, null: false)
      add(:product_symbol, :string, null: false)
      add(:product_type, :string, null: false)
      add(:qty, :decimal, null: false)
      add(:side, :string, null: false)
      add(:status, :string, null: false)
      add(:time_in_force, :string, null: false)
      add(:type, :string, null: false)
      add(:venue, :string, null: false)
      add(:venue_order_id, :string)
      add(:venue_product_symbol, :string, null: false)

      timestamps([type: :utc_datetime_usec])
    end

    # Used to lookup the order when applying an order transition
    create index(:orders, [:client_id, :status])
    # Used to sort the orders command
    create index(:orders, :inserted_at)
  end
end
