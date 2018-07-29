defmodule Tai.Exchanges.BalanceRange do
  @type t :: %Tai.Exchanges.BalanceRange{
          asset: atom,
          min: Decimal.t(),
          max: Decimal.t()
        }
  @type qty :: number | String.t() | Decimal.t()

  @enforce_keys [:asset, :min, :max]
  defstruct [:asset, :min, :max]

  @spec new(atom, qty, qty) :: t
  def new(asset, min, max)

  def new(asset, %Decimal{} = min, %Decimal{} = max) do
    %Tai.Exchanges.BalanceRange{
      asset: asset,
      min: min,
      max: max
    }
  end

  def new(asset, min, max) do
    new(asset, Decimal.new(min), Decimal.new(max))
  end

  @spec validate(t) :: :ok | {:error, :min_less_than_zero | :min_greater_than_max}
  def validate(%Tai.Exchanges.BalanceRange{min: min, max: max}) do
    cond do
      Decimal.cmp(min, Decimal.new(0)) == :lt -> {:error, :min_less_than_zero}
      Decimal.cmp(min, max) == :gt -> {:error, :min_greater_than_max}
      true -> :ok
    end
  end
end
