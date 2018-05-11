defmodule Examples.Advisors.LogSpread.Supervisor do
  use Supervisor

  alias Tai.Advisors.Config
  alias Examples.Advisors.LogSpread

  def start_link([id: _] = state) do
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(id: id) do
    [
      %{
        id: id,
        start: {LogSpread.Advisor, :start_link, [params(id)]}
      }
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp params(id) do
    [
      advisor_id: id,
      order_books: Config.order_books(id),
      exchanges: [],
      store: %{}
    ]
  end
end
