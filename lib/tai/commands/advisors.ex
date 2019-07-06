defmodule Tai.Commands.Advisors do
  import Tai.Commands.Table, only: [render!: 2]

  @header [
    "Group ID",
    "Advisor ID",
    "Status",
    "PID"
  ]

  @spec list() :: no_return
  @spec list(list) :: no_return
  def list(args \\ []) do
    store_id = Keyword.get(args, :store_id, Tai.Advisors.Store.default_store_id())
    filters = Keyword.get(args, :where, [])
    order_by = Keyword.get(args, :order, [:group_id, :advisor_id])

    filters
    |> Tai.Advisors.Instances.where(store_id)
    |> Enumerati.order(order_by)
    |> format_rows()
    |> render!(@header)
  end

  @spec start() :: no_return
  @spec start(list) :: no_return
  def start(args \\ []) do
    store_id = Keyword.get(args, :store_id, Tai.Advisors.Store.default_store_id())
    filters = Keyword.get(args, :where, [])

    {started, already_started} =
      filters
      |> Tai.Advisors.Instances.where(store_id)
      |> Tai.Advisors.Instances.start()

    IO.puts("Started advisors: #{started} new, #{already_started} already running")
    IEx.dont_display_result()
  end

  @spec stop() :: no_return
  @spec stop(list) :: no_return
  def stop(args \\ []) do
    store_id = Keyword.get(args, :store_id, Tai.Advisors.Store.default_store_id())
    filters = Keyword.get(args, :where, [])

    {stopped, already_stopped} =
      filters
      |> Tai.Advisors.Instances.where(store_id)
      |> Tai.Advisors.Instances.stop()

    IO.puts("Stopped advisors: #{stopped} new, #{already_stopped} already stopped")
    IEx.dont_display_result()
  end

  defp format_rows(instances) do
    instances
    |> Enum.map(fn instance ->
      [
        instance.group_id,
        instance.advisor_id,
        instance.status,
        instance.pid |> format_col
      ]
    end)
  end

  defp format_col(val) when is_pid(val) or is_map(val), do: val |> inspect()
  defp format_col(nil), do: "-"
  defp format_col(val), do: val
end
