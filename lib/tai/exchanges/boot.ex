defmodule Tai.Exchanges.Boot do
  @moduledoc """
  Coordinates the asynchronous hydration of a venue:

  - products
  - asset balances
  - fees
  """

  alias Tai.Exchanges.Boot

  @type adapter :: Tai.Exchanges.Adapter.t()

  @spec run(adapter :: adapter) :: {:ok, adapter} | {:error, [reasons :: term]}
  def run(%Tai.Exchanges.Adapter{} = adapter) do
    adapter
    |> hydrate_products_and_balances
    |> wait_for_products
    |> hydrate_fees_and_start_order_books
    |> wait_for_balances_and_fees
  end

  defp hydrate_products_and_balances(adapter) do
    t_products = Task.async(Boot.Products, :hydrate, [adapter])
    t_balances = Task.async(Boot.AssetBalances, :hydrate, [adapter])
    {adapter, t_products, t_balances}
  end

  defp wait_for_products({adapter, t_products, t_balances}) do
    working_tasks = [asset_balances: t_balances]

    case Task.await(t_products, adapter.timeout) do
      {:ok, products} ->
        {:ok, adapter, working_tasks, products}

      {:error, reason} ->
        err_reasons = [products: reason]
        {:error, adapter, working_tasks, err_reasons}
    end
  end

  defp hydrate_fees_and_start_order_books({:ok, adapter, working_tasks, products}) do
    t_fees = Task.async(Boot.Fees, :hydrate, [adapter, products])
    t_order_books = Task.async(Boot.OrderBooks, :start, [adapter, products])
    new_working_tasks = [{:fees, t_fees} | working_tasks]
    new_working_tasks = [{:order_books, t_order_books} | new_working_tasks]
    {:ok, adapter, new_working_tasks}
  end

  defp hydrate_fees_and_start_order_books({:error, _, _, _} = error), do: error

  defp wait_for_balances_and_fees({:ok, adapter, working_tasks}) do
    adapter
    |> collect_remaining_errors(working_tasks, [])
  end

  defp wait_for_balances_and_fees({:error, adapter, working_tasks, err_reasons}) do
    adapter
    |> collect_remaining_errors(working_tasks, err_reasons)
  end

  defp collect_remaining_errors(adapter, [], err_reasons) do
    if Enum.empty?(err_reasons) do
      {:ok, adapter}
    else
      {:error, {adapter, err_reasons}}
    end
  end

  defp collect_remaining_errors(adapter, [{name, working} | tasks], err_reasons) do
    case Task.await(working, adapter.timeout) do
      {:error, reason} ->
        adapter |> collect_remaining_errors(tasks, [{name, reason} | err_reasons])

      _ ->
        adapter |> collect_remaining_errors(tasks, err_reasons)
    end
  end
end
