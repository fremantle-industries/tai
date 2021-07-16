defmodule Tai.Orders.Supervisor do
  use Supervisor

  alias Tai.Orders.{
    OrderCallbackStore,
    OrderRepo,
    OrderTransitionSupervisor,
    Worker
  }

  @type config :: Tai.Config.t()

  @spec start_link(config) :: Supervisor.on_start()
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    [
      OrderRepo,
      OrderCallbackStore,
      {OrderTransitionSupervisor, config.order_transition_workers},
      :poolboy.child_spec(
        :worker,
        [
          {:name, {:local, Tai.Orders.pool_name()}},
          {:worker_module, Worker},
          {:size, config.order_workers},
          {:max_overflow, config.order_workers_max_overflow}
        ]
      )
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
