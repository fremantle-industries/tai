defmodule Tai.Advisors.Supervisor do
  use Supervisor

  alias Tai.{Advisor, Advisors.Config, Exchanges}

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Config.all
    |> to_children
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp to_children(advisors) do
    advisors
    |> Enum.map(&config_to_child_spec/1)
  end

  defp config_to_child_spec({advisor_id, advisor}) do
    Supervisor.child_spec(
      {
        advisor,
        [advisor_id: advisor_id, order_book_feed_ids: Exchanges.Config.order_book_feed_ids]
      },
      id: advisor_id |> Advisor.to_name
    )
  end
end
