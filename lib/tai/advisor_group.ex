defmodule Tai.AdvisorGroup do
  @type t :: %Tai.AdvisorGroup{
          id: atom,
          advisor: atom,
          factory: atom,
          products: String.t(),
          store: map
        }

  @enforce_keys [:id, :factory, :products, :store]
  defstruct [:id, :advisor, :factory, :products, :store]
end
