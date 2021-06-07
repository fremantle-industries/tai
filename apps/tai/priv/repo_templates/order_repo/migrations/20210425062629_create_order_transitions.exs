defmodule Tai.NewOrders.OrderRepo.Migrations.CreateOrderTransitions do
  use Ecto.Migration

  def change do
    create table(:order_transitions, primary_key: false) do
      add(:id, :uuid, null: false, primary_key: true)
      add(:order_client_id, references(:orders, column: :client_id, type: :uuid, on_delete: :delete_all))
      add(:transition, :map, null: false)

      timestamps()
    end
  end
end
