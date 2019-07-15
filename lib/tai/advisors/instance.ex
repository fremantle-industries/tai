defmodule Tai.Advisors.Instance do
  alias Tai.Advisors.{Instance, Spec}

  @type spec :: Spec.t()
  @type status :: :unstarted | :running
  @type t :: %Instance{
          mod: Spec.mod(),
          start_on_boot: boolean,
          group_id: Spec.group_id(),
          advisor_id: Spec.advisor_id(),
          products: [Spec.product()],
          config: Spec.config(),
          trades: [struct],
          run_store: Tai.Advisor.run_store(),
          pid: pid,
          status: status
        }

  @enforce_keys ~w(mod start_on_boot group_id advisor_id products config pid status)a
  defstruct ~w(mod start_on_boot group_id advisor_id products config trades run_store pid status)a

  @spec from_spec(spec) :: t
  def from_spec(spec) do
    pid = spec |> whereis()
    status = pid |> to_status()

    %Instance{
      mod: spec.mod,
      start_on_boot: spec.start_on_boot,
      group_id: spec.group_id,
      advisor_id: spec.advisor_id,
      products: spec.products,
      config: spec.config,
      trades: spec.trades,
      run_store: spec.run_store,
      pid: pid,
      status: status
    }
  end

  @spec to_spec(t) :: spec
  def to_spec(instance) do
    %Spec{
      mod: instance.mod,
      start_on_boot: instance.start_on_boot,
      group_id: instance.group_id,
      advisor_id: instance.advisor_id,
      products: instance.products,
      config: instance.config,
      trades: instance.trades,
      run_store: instance.run_store
    }
  end

  defp whereis(spec) do
    name = Tai.Advisor.to_name(spec.group_id, spec.advisor_id)
    Process.whereis(name)
  end

  defp to_status(val) when is_pid(val), do: :running
  defp to_status(_), do: :unstarted
end
