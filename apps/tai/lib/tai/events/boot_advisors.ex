defmodule Tai.Events.BootAdvisors do
  @type t :: %__MODULE__{
    loaded_fleets: non_neg_integer,
    loaded_advisors: non_neg_integer,
    started_advisors: non_neg_integer
  }

  @enforce_keys ~w[loaded_fleets loaded_advisors started_advisors]a
  defstruct ~w[loaded_fleets loaded_advisors started_advisors]a
end
