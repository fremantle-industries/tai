defmodule Tai.Advisors.Instances do
  alias Tai.Advisors.{Instance, SpecStore}

  @type store_id :: SpecStore.store_id()
  @type instance :: Instance.t()

  @spec where(list, store_id) :: [instance]
  def where(filters, store_id) do
    store_id
    |> SpecStore.all()
    |> Enum.map(&Instance.from_spec/1)
    |> Enumerati.filter(filters)
  end

  @spec start([instance]) :: {started :: pos_integer, already_started :: pos_integer}
  def start(instances) do
    instances
    |> Enum.map(&Instance.to_spec/1)
    |> Enum.map(&Tai.Advisor.child_spec/1)
    |> Enum.map(&Tai.Advisors.Supervisor.start_advisor/1)
    |> Enum.reduce(
      {0, 0},
      fn
        {:ok, _}, {s, a} -> {s + 1, a}
        {:error, {:already_started, _}}, {s, a} -> {s, a + 1}
      end
    )
  end

  @spec stop([instance]) :: {stopped :: pos_integer, already_stopped :: pos_integer}
  def stop(instances) do
    instances
    |> Enum.map(& &1.pid)
    |> Enum.reduce(
      {0, 0},
      fn
        nil, {s, a} ->
          {s, a + 1}

        pid, {s, a} ->
          pid
          |> Tai.Advisors.Supervisor.terminate_advisor()
          |> case do
            :ok -> {s + 1, a}
            {:error, :not_found} -> {s, a + 1}
          end
      end
    )
  end
end
