defmodule Tai.Events.BootAdvisors do
  alias __MODULE__

  @type t :: %BootAdvisors{
          total: non_neg_integer,
          started: non_neg_integer
        }

  @enforce_keys ~w(total started)a
  defstruct ~w(total started)a
end
