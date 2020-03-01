defmodule TaiEventsSupport.CustomEvent do
  alias __MODULE__

  @type t :: %CustomEvent{hello: term}

  defstruct ~w(hello)a
end

defimpl TaiEvents.LogEvent, for: TaiEventsSupport.CustomEvent do
  def to_data(_event) do
    %{hello: :custom}
  end
end
