defmodule Tai.Exchanges.OrderBookFeedsSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    Tai.Exchanges.Config.order_book_feed_ids()
    |> to_children
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp to_children(feed_ids) do
    feed_ids
    |> Enum.map(
      &Supervisor.child_spec(
        {Tai.Exchanges.OrderBookFeedSupervisor, &1},
        id: "#{Tai.Exchanges.OrderBookFeedSupervisor}_#{&1}"
      )
    )
  end
end
