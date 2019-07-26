defmodule Support.CustomEvent do
  @type t :: %Support.CustomEvent{
          hello: term
        }

  defstruct [:hello]
end

defimpl Tai.LogEvent, for: Support.CustomEvent do
  def to_data(_event), do: %{hello: :custom}
end
