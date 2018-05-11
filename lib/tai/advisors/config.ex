defmodule Tai.Advisors.Config do
  alias Tai.Exchanges

  def all(config \\ Application.get_env(:tai, :advisors)) do
    config || []
  end

  def find(advisor_id) do
    all()
    |> Enum.find(fn %{id: config_id} -> advisor_id == config_id end)
  end

  def order_books(advisor_id) do
    query =
      advisor_id
      |> find
      |> Map.get(:order_books)

    order_books_by_exchange()
    |> Juice.squeeze(query)
  end

  defp order_books_by_exchange do
    Exchanges.Config.order_book_feeds()
    |> Enum.reduce(
      %{},
      fn {adapter_id, [adapter: _, order_books: order_books]}, acc ->
        Map.put(acc, adapter_id, order_books)
      end
    )
  end
end
