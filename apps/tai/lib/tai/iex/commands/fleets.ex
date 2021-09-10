defmodule Tai.IEx.Commands.Fleets do
  import Tai.IEx.Commands.Table, only: [render!: 2]

  @header [
    "ID",
    "Start on Boot",
    "Quotes",
    "Factory",
    "Advisor"
  ]

  @type store_id_opt :: {:store_id, atom}
  @type where_opt :: {:where, list}
  @type order_opt :: {:order, list}
  @type options :: [store_id_opt | where_opt | order_opt]

  @spec list(options) :: no_return
  def list(options) do
    options
    |> Tai.Commander.fleets()
    |> format_rows()
    |> render!(@header)
  end

  defp format_rows(fleets) do
    fleets
    |> Enum.map(fn f ->
      [
        f.id,
        f.start_on_boot,
        f.quotes,
        f.factory,
        f.advisor
      ]
      |> Enum.map(&format_col/1)
    end)
  end

  defp format_col(val) when is_pid(val) or is_map(val), do: val |> inspect()
  defp format_col(nil), do: "-"
  defp format_col(val), do: val
end
