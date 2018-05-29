defmodule Tai.Trading.Supervisor do
  @moduledoc """
  Supervisor that manages the processes for trade execution and tracking
  """

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      Tai.Trading.OrderStore
      # {
      #   Tai.Trading.OrderPipeline,
      #   [send_orders_enabled: Tai.Settings.send_orders_enabled()]
      # }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
