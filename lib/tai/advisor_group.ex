defmodule Tai.AdvisorGroup do
  @type id :: atom
  @type t :: %Tai.AdvisorGroup{
          id: id,
          advisor: atom,
          factory: atom,
          products: String.t(),
          config: map | struct,
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
