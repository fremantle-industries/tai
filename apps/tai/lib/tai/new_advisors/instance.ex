defmodule Tai.NewAdvisors.Instance do
  @type t :: %__MODULE__{}

  @enforce_keys ~w[advisor_id fleet_id status pid start_on_boot restart shutdown]a
  defstruct ~w[advisor_id fleet_id status pid start_on_boot restart shutdown config]a
end
