defmodule Tai.NewOrders.OrderRepo.Migrations.CreateFailedOrderTransitions do
  use Ecto.Migration

  def change do
    create table(:failed_order_transitions) do
      add(:order_client_id, references(:orders, column: :client_id, type: :uuid), null: false)
      add(:type, :string)
      add(:error, :binary, null: false)

      timestamps()
    end
  end
end
