defmodule Tai.Exchanges.Config do
  @moduledoc """
  Configuration helper for exchanges
  """

  @type t :: %Tai.Exchanges.Config{}

  @enforce_keys [:id, :supervisor]
  defstruct id: nil, supervisor: nil, products: "*", accounts: %{}

  @doc """
  Return a struct for all configured exchanges 

  ## Examples

    iex> Tai.Exchanges.Config.all
    [
      %Tai.Exchanges.Config{
        id: :test_exchange_a,
        supervisor: Tai.ExchangeAdapters.Mock.Supervisor,
        products: "*",
        accounts: %{main: %{}}
      },
      %Tai.Exchanges.Config{
        id: :test_exchange_b,
        supervisor: Tai.ExchangeAdapters.Mock.Supervisor,
        products: "*",
        accounts: %{main: %{}}
      }
    ]
  """
  @spec all :: [t]
  def all(exchanges \\ Application.get_env(:tai, :exchanges)) do
    exchanges
    |> Enum.map(fn {id, params} ->
      %Tai.Exchanges.Config{
        id: id,
        supervisor: Keyword.get(params, :supervisor),
        products: Keyword.get(params, :products, "*"),
        accounts: Keyword.get(params, :accounts, %{})
      }
    end)
  end
end
