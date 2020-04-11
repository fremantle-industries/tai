defmodule Tai.IEx.Commands.AdvisorGroups do
  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Group",
    "Running",
    "Starting",
    "Stopped",
    "Total"
  ]

  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type order_opt :: {:order, list}
  @type options :: [store_id_opt | where_opt | order_opt]

  @spec list(options) :: no_return
  def list(options) do
    options
    |> Tai.Commander.advisor_groups()
    |> format_rows()
    |> render!(@header)
  end

  defp format_rows(groups) do
    groups
    |> Enum.map(fn g ->
      running = Enum.count(g.running)
      starting = Enum.count(g.starting)
      stopped = Enum.count(g.stopped)

      [
        g.id,
        running,
        starting,
        stopped,
        running + starting + stopped
      ]
      |> Enum.map(&format_col/1)
    end)
  end

  defp format_col(nil), do: "-"
  defp format_col(val), do: val
end
