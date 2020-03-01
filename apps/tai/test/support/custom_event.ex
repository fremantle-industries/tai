defmodule Support.CustomEvent do
  @type t :: %Support.CustomEvent{
          hello: term
        }

  defstruct ~w(hello)a
end

defimpl TaiEvents.LogEvent, for: Support.CustomEvent do
  def to_data(_event), do: %{hello: :custom}
end
