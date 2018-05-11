defmodule Examples.Advisors.CreateAndCancelPendingOrder.Supervisor do
  use Supervisor

  alias Tai.Advisors.Config
  alias Examples.Advisors.CreateAndCancelPendingOrder

  def start_link([id: _] = state) do
    Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(id: id) do
    id
    |> Config.order_books()
    |> Enum.reduce(
      [],
      fn {feed_id, symbols}, acc ->
        symbols
        |> Enum.reduce(
          acc,
          fn symbol, acc -> [config(id, feed_id, symbol) | acc] end
        )
      end
    )
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp params(advisor_id, feed_id, symbol) do
    [
      advisor_id: advisor_id,
      order_books: Map.put(%{}, feed_id, [symbol]),
      exchanges: [],
      store: %{}
    ]
  end

  defp config(id, feed_id, symbol) do
    advisor_id = :"#{id}_#{feed_id}_#{symbol}"

    %{
      id: advisor_id,
      start: {
        CreateAndCancelPendingOrder.Advisor,
        :start_link,
        [params(advisor_id, feed_id, symbol)]
      }
    }
  end
end
