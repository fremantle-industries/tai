defmodule Tai.AdvisorGroup do
  @type t :: %Tai.AdvisorGroup{
          id: atom,
          factory: atom,
          products: String.t()
        }

  @enforce_keys [:id, :factory, :products]
  defstruct [:id, :factory, :products]
end
