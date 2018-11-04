defmodule Tai.AdvisorGroup do
  @type t :: %Tai.AdvisorGroup{
          id: atom,
          advisor: atom,
          factory: atom,
          products: String.t(),
          config: map
        }

  @enforce_keys [:id, :factory, :products, :config]
  defstruct [:id, :advisor, :factory, :products, :config]
end
