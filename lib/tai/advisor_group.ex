defmodule Tai.AdvisorGroup do
  @type id :: atom
  @type t :: %Tai.AdvisorGroup{
          id: id,
          start_on_boot: boolean,
          advisor: atom,
          factory: atom,
          products: String.t(),
          config: map | struct,
          trades: list
        }

  @enforce_keys ~w(id start_on_boot factory products config trades)a
  defstruct ~w(id start_on_boot advisor factory products config trades)a

  use Vex.Struct

  validates(:id, presence: true)
  validates(:start_on_boot, inclusion: [true, false])
  validates(:advisor, presence: true)
  validates(:factory, presence: true)
  validates(:products, presence: true)
end
