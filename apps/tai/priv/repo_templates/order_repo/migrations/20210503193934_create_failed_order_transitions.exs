defmodule Tai.Orders.OrderRepo.Migrations.CreateFailedOrderTransitions do
  use Ecto.Migration

  def change do
    create table(:failed_order_transitions) do
      add(:order_client_id, references(:orders, column: :client_id, type: :uuid, on_delete: :delete_all), null: false)
      add(:type, :string)
      add(:error, :binary, null: false)

      timestamps([type: :utc_datetime_usec])
    end
  end
end
