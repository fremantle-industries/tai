defmodule Tai.Supervisor do
  @moduledoc """
  Root supervisor for tai components
  """

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      Tai.PubSub,
      {Tai.Settings, Tai.Config.all()},
      Tai.Trading.OrderStore,
      Tai.Advisors.Supervisor,
      Tai.Exchanges.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
