defmodule Tai.Venues.Boot do
  @moduledoc """
  Coordinates the asynchronous hydration of a venue:

  - products
  - accounts
  - fees
  """

  alias __MODULE__

  @type venue :: Tai.Venue.t()

  @spec run(venue) :: {:ok, venue} | {:error, {venue, [reason :: term]}}
  def run(venue) do
    venue
    |> hydrate_products_and_accounts
    |> wait_for_products
    |> hydrate_fees_and_positions_and_start_streams
    |> wait_for_accounts_and_fees
  end

  defp hydrate_products_and_accounts(venue) do
    t_products = Task.async(Boot.Products, :hydrate, [venue])
    t_accounts = Task.async(Boot.Accounts, :hydrate, [venue])
    {venue, t_products, t_accounts}
  end

  defp wait_for_products({venue, t_products, t_accounts}) do
    working_tasks = [accounts: t_accounts]

    case Task.await(t_products, venue.timeout) do
      {:ok, products} ->
        {:ok, venue, working_tasks, products}

      {:error, reason} ->
        err_reasons = [products: reason]
        {:error, venue, working_tasks, err_reasons}
    end
  end

  defp hydrate_fees_and_positions_and_start_streams({:ok, venue, working_tasks, products}) do
    t_fees = Task.async(Boot.Fees, :hydrate, [venue, products])
    t_positions = Task.async(Boot.Positions, :hydrate, [venue])
    t_stream = Task.async(Boot.Stream, :start, [venue, products])
    new_working_tasks = [{:fees, t_fees} | working_tasks]
    new_working_tasks = [{:positions, t_positions} | new_working_tasks]
    new_working_tasks = [{:streams, t_stream} | new_working_tasks]
    {:ok, venue, new_working_tasks}
  end

  defp hydrate_fees_and_positions_and_start_streams({:error, _, _, _} = error), do: error

  defp wait_for_accounts_and_fees({:ok, venue, working_tasks}) do
    venue
    |> collect_remaining_errors(working_tasks, [])
  end

  defp wait_for_accounts_and_fees({:error, venue, working_tasks, err_reasons}) do
    venue
    |> collect_remaining_errors(working_tasks, err_reasons)
  end

  defp collect_remaining_errors(venue, [], err_reasons) do
    if Enum.empty?(err_reasons) do
      {:ok, venue}
    else
      {:error, {venue, err_reasons}}
    end
  end

  defp collect_remaining_errors(venue, [{name, working} | tasks], err_reasons) do
    case Task.await(working, venue.timeout) do
      {:error, reason} ->
        venue |> collect_remaining_errors(tasks, [{name, reason} | err_reasons])

      _ ->
        venue |> collect_remaining_errors(tasks, err_reasons)
    end
  end
end
