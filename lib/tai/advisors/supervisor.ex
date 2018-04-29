defmodule Tai.Advisors.Supervisor do
  use Supervisor

  alias Tai.{Advisor, Advisors.Config}

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Config.modules()
    |> Enum.map(&config_to_child_spec/1)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp config_to_child_spec({advisor_id, module}) do
    Supervisor.child_spec(
      {
        module,
        [
          advisor_id: advisor_id,
          order_books: Config.order_books(advisor_id),
          exchanges: Config.exchanges(advisor_id),
          store: %{}
        ]
      },
      id: advisor_id |> Advisor.to_name()
    )
  end
end
