defmodule Tai.Exchanges.BalanceDetail do
  @type t :: %Tai.Exchanges.BalanceDetail{free: Decimal.t(), locked: Decimal.t()}

  @enforce_keys [:free, :locked]
  defstruct [:free, :locked]

  @spec new(number, number) :: t
  def new(free, locked) do
    %Tai.Exchanges.BalanceDetail{
      free: Decimal.new(free),
      locked: Decimal.new(locked)
    }
  end

  @spec total(t) :: Decimal.t()
  def total(detail) do
    Decimal.add(detail.free, detail.locked)
  end
end
