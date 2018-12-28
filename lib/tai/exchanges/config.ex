defmodule Tai.Exchanges.Config do
  @type t :: %Tai.Exchanges.Config{}

  @enforce_keys [:id, :supervisor]
  defstruct id: nil, supervisor: nil, products: "*", accounts: %{}
end
