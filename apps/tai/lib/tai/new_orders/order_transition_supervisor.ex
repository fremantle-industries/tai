defmodule Tai.NewOrders.OrderTransitionSupervisor do
  use Supervisor
  alias Tai.NewOrders.OrderTransitionWorker

  @spec start_link(pos_integer) :: Supervisor.on_start()
  def start_link(worker_count) do
    Supervisor.start_link(__MODULE__, worker_count, name: __MODULE__)
  end

  @impl true
  def init(worker_count) do
    children =
      0
      |> Range.new(worker_count - 1)
      |> Enum.map(fn idx ->
        Supervisor.child_spec(
          {OrderTransitionWorker, idx},
          id: :"#{OrderTransitionWorker}_#{idx}"
        )
      end)

    children
    |> Supervisor.init(strategy: :one_for_one)
  end
end
