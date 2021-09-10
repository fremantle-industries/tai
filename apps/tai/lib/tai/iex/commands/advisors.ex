defmodule Tai.IEx.Commands.Advisors do
  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "Fleet ID",
    "Advisor ID",
    "Status",
    "PID",
    "Config"
  ]

  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type order_opt :: {:order, list}
  @type options :: [store_id_opt | where_opt | order_opt]

  @spec list(options) :: no_return
  def list(options) do
    options
    |> Tai.Commander.advisors()
    |> format_rows()
    |> render!(@header)
  end

  defp format_rows(instances) do
    instances
    |> Enum.map(fn i ->
      [
        i.fleet_id,
        i.advisor_id,
        i.status,
        i.pid,
        i.config
      ]
      |> Enum.map(&format_col/1)
    end)
  end

  defp format_col(val) when is_pid(val) or is_map(val), do: val |> inspect()
  defp format_col(nil), do: "-"
  defp format_col(val), do: val
end
