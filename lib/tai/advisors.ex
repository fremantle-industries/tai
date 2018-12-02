defmodule Tai.Advisors do
  @type advisor_spec :: {atom, [group_id: atom, advisor_id: atom, order_books: map, store: map]}

  @spec info([advisor_spec]) :: [{advisor_spec, pid}]
  def info(specs) do
    specs
    |> Enum.map(fn {_, opts} = spec ->
      group_id = Keyword.fetch!(opts, :group_id)
      advisor_id = Keyword.fetch!(opts, :advisor_id)
      name = Tai.Advisor.to_name(group_id, advisor_id)
      pid = Process.whereis(name)

      {spec, pid}
    end)
  end

  @spec start([advisor_spec]) :: {:ok, {new_started :: integer, old_started :: integer}}
  def start(specs) do
    counts =
      specs
      |> Tai.Advisors.info()
      |> Enum.reduce({0, 0}, &start_advisor/2)

    {:ok, counts}
  end

  @spec stop([advisor_spec]) :: {:ok, {new_stopped :: integer, old_stopped :: integer}}
  def stop(specs) do
    counts =
      specs
      |> Tai.Advisors.info()
      |> Enum.reduce({0, 0}, &stop_advisor/2)

    {:ok, counts}
  end

  defp start_advisor({_, pid}, {new, old}) when is_pid(pid) do
    {new, old + 1}
  end

  defp start_advisor({spec, nil}, {new, old}) do
    Tai.AdvisorsSupervisor.start_advisor(spec)
    {new + 1, old}
  end

  defp stop_advisor({_, pid}, {new, old}) when is_pid(pid) do
    Tai.AdvisorsSupervisor.terminate_advisor(pid)
    {new + 1, old}
  end

  defp stop_advisor({_, nil}, {new, old}) do
    {new, old + 1}
  end
end
