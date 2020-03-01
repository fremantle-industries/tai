defmodule TaiEvents.Application do
  use Application

  def start(_type, args) do
    partitions = Keyword.get(args, :partitions, System.schedulers_online())

    children = [
      {TaiEvents, partitions}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: TaiEvents.Supervisor)
  end
end
