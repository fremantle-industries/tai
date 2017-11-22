defmodule Tai.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      Tai.Strategies.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
