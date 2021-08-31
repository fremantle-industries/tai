defmodule Tai.NewAdvisors do
  alias __MODULE__

  @type start_result :: {started :: non_neg_integer, already_started :: non_neg_integer}
  @type stop_result :: {stopped :: non_neg_integer, already_stopped :: non_neg_integer}

  @spec search_instances(term) :: NewAdvisors.Queries.SearchInstances.result()
  def search_instances(query) do
    NewAdvisors.Queries.SearchInstances.call(query)
  end

  @spec search_configs(term) :: NewAdvisors.Queries.SearchConfigs.result()
  def search_configs(options) do
    NewAdvisors.Queries.SearchConfigs.call(options)
  end

  @spec start(term) :: start_result
  def start(options) do
    options
    |> search_configs()
    |> Enum.map(&NewAdvisors.Supervisor.start_advisor/1)
    |> Enum.reduce(
      {0, 0},
      fn
        {:error, {:already_started, _}}, {s, a} -> {s, a+1}
        _, {s, a} -> {s+1, a}
      end
    )
  end

  @spec stop(term) :: stop_result
  def stop(options) do
    options
    |> search_instances()
    |> Enum.reduce(
      {0, 0},
      fn
        %_{pid: nil}, {stopped, already_stopped} ->
          {stopped, already_stopped+1}

        i, {stopped, already_stopped} ->
          :ok = NewAdvisors.Supervisor.terminate_advisor(i.pid)
          {stopped+1, already_stopped}
      end
    )
  end
end
