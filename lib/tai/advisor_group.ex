defmodule Tai.AdvisorGroup do
  @type t :: %Tai.AdvisorGroup{
          id: atom,
          advisor: atom,
          factory: atom,
          products: String.t(),
          config: map,
          trades: list
        }

  @enforce_keys ~w(id factory products config trades)a
  defstruct ~w(id advisor factory products config trades)a
  use Vex.Struct

  validates(:id, presence: true)
  validates(:advisor, presence: true)
  validates(:factory, presence: true)
  validates(:products, presence: true)
end
