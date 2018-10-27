defmodule Tai.AdvisorGroup do
  @type t :: %Tai.AdvisorGroup{
          id: atom,
          factory: atom,
          products: String.t(),
          store: map
        }

  @enforce_keys [:id, :factory, :products, :store]
  defstruct [:id, :factory, :products, :store]
end
